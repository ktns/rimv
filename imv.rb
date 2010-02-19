#!/usr/bin/ruby
# vim: set foldmethod=syntax :
APP_NAME = "imv"

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

		def addimage name, img
			raise TypeError unless img.kind_of?(String)
			hash = Digest::MD5.digest(img).unpack('h*').first
			@db.transaction do |db|
				begin
				db.execute('insert into img values(?,?,?)', hash,
									 Blob.new(img), $score || 0)
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
			case $score
			when nil
				@db.execute(<<SQL).collect {|set| set.first}
SELECT hash
FROM img
SQL
			when Integer
				@db.execute(<<SQL, $score).collect {|set| set.first}
SELECT hash
FROM img
WHERE score = ?
SQL
			when Range
				@db.execute(<<SQL, $score.begin, $score.last).collect {|set| set.first}
SELECT hash
FROM img
WHERE score BETWEEN ? AND ?
SQL
			else
				raise ScriptError
			end
		end
	end

	require "gtk2"
	class MainWin < Gtk::Window
		def initialize db, hash_list
			raise TypeError, "IMV::DB expected for `db', but #{db.class}" unless db.kind_of?(IMV::DB)
			raise TypeError, "Array expected for `hash_list', but #{hash_list.class}" unless hash_list.kind_of?(Array)

			super(APP_NAME)
			set_default_size(*WINDOW_SIZE)
			@db = db
			@hash_list = hash_list

			signal_connect("delete_event") do
				Gtk.main_quit
			end
			signal_connect("key-press-event") do |w, e|
				case e.keyval
				when Gdk::Keyval::GDK_q
					Gtk.main_quit
				when Gdk::Keyval::GDK_space
					display_next
				end
			end
			@cur_img = nil
			display @hash_list[@cur_index = 0]
		end

		private
		def display hash
			remove(@cur_img) if @cur_img
			@cur_img = @db.getimage(hash)

			width, height = @cur_img.pixbuf.width, @cur_img.pixbuf.height

			if width > WINDOW_SIZE[0] || height > WINDOW_SIZE[1]
				@cur_img.pixbuf = @cur_img.pixbuf.scale(*WINDOW_SIZE)
			end
			add(@cur_img)
			show_all
		end

		def display_next
			display(@hash_list[@cur_index = ((@cur_index+1) % @hash_list.length)])
		end
	end
end

if $0 == __FILE__
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
		opt.on('-s=VAL', '--score=VAL',
					 'score of the image to be displayed or added') {|val|
			if val =~ /\A(-?d+)([+-])\Z/
				if $2 == '+'
					$score = (eval $1)..1.0/0
				else
					$score = -1.0/0..(eval $1)
				end
			else
				$score = eval val
				unless [Integer,Range].any?{|cls| $score.kind_of?(cls)}
					raise ArgumentError, "Can't parse score value string `#{val}'!"
				end
			end
		}

		opt.parse!
	end

	case $mode
	when 'add'
		raise 'No file to add!' if ARGV.empty?
		raise "Non-integer score is not acceptable in `add' mode!" unless ! $score || $score.kind_of?(Integer)
		IMV::DB.open do |db|
			ARGV.each do |name|
				db.addfile(name)
			end
		end
	when 'view',nil
		WINDOW_SIZE = [640, 480]

		IMV::DB.open do |db|
			abort 'No Image!' if (hashlist = db.getallhash).empty?
			main_win = IMV::MainWin.new(db, hashlist)
			Gtk.main
		end
	else
		raise NotImplementedError, "mode = #{mode}"
	end
end
