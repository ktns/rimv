#!/usr/bin/ruby
# vim: set foldmethod=syntax :
APP_NAME = "imv"

require 'optparse'

$mode = nil

ARGV.options do |opt|
	MODES={
		'add'=>'add image(s) to database',
		'view'=>'view images in database'
	}.each do |mode,desc|
		opt.on('-'+mode[0,1],'--'+mode,desc) do |v|
			if $mode
				$stderr.printf("multiple mode option specified!('%s' after '%s')\n",
											 mode, $mode)
				abort
			else
				$mode = mode
			end
		end
	end
	$verbose=false
	opt.on('--verbose', 'verbosely report information'){$verbose=true}

	opt.parse!
end

module IMV
	class DB
		require 'sqlite3'
		require 'digest/md5'

		include SQLite3

		private_class_method :new

		public
		def self.open
			db = new
			begin
				yield db
			ensure
				db.close
			end
		end

		def initialize
			@db = Database.new("#{ENV['HOME']}/.imv.sqlite3")
		end

		def close
			@db.close
		end

		def addimage name,img
			raise TypeError unless img.kind_of?(String)
			hash = Digest::MD5.digest(img)
			@db.transaction do |db|
				hash = Digest::MD5.digest(img)
				begin
				db.execute('insert into img values(?,?)', hash,
									 Blob.new(img) )
				rescue SQLException
					unless $!.message.include?('column hash is not unique')
						raise $!
					end
				end
				db.execute('insert into name values(?,?)', hash, File.basename(name) )
			end and hash
		end

		def addfile path
			if File.directory?(path)
				Dir.foreach(path) do |file|
					next if %w<. ..>.include?(file)
					$stderr.puts "adding directory `#{path}/#{file}'" if $verbose
					addfile("#{path}/#{file}")
				end
			elsif File.file?(path)
				File.open(path) do |file|
					$stderr.puts "adding file `#{path}'" if $verbose
					addimage(path,file.read)
				end
			else
				raise ArgumentError
			end
		end

		def getimage hash
			require 'tempfile'
			tmp = Tempfile.new(APP_NAME)
			begin
				tmp.write(
					@db.execute(<<SQL,hash).collect.first.first
SELECT img
FROM img
WHERE hash = ?
LIMIT 1
SQL
				)
				tmp.close
				return Gtk::Image.new(tmp.path)
			ensure
				tmp.close(true)
			end
		end

		def getallhash
			@db.execute(<<SQL).collect {|set| set.first}
SELECT hash
FROM img
SQL
		end
	end
end

case $mode
when 'add'
	IMV::DB.open do |db|
		ARGV.each do |name|
			db.addfile(name)
		end
	end
when 'view',nil
	require "gtk2"

	WINDOW_SIZE = [640, 480]

	class MainWin < Gtk::Window
		def initialize
			super(APP_NAME)
			set_default_size(*WINDOW_SIZE)

			signal_connect("delete_event") do
				Gtk.main_quit
			end
			signal_connect("key-press-event") do |w, e|
				if e.keyval == Gdk::Keyval::GDK_q
					Gtk.main_quit
				end
			end
		end
	end

	IMV::DB.open do |db|
		image = db.getimage(db.getallhash.first)
		width, height = image.pixbuf.width, image.pixbuf.height

		if width > WINDOW_SIZE[0] || height > WINDOW_SIZE[1]
			image.pixbuf = image.pixbuf.scale(*WINDOW_SIZE)
		end

		main_win = MainWin.new
		main_win.add(image)
		main_win.show_all
		Gtk.main
	end
else
	raise NotImplementedError, "mode = #{mode}"
end
