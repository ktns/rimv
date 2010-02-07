#!/usr/bin/ruby
# vim: set foldmethod=syntax :

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
	end
end

case $mode
when 'add'
	IMV::DB.open do |db|
		#TODO: DBに画像を追加
	end
when 'view',nil
	require "gtk2"

	APP_NAME = "rview"
	WINDOW_SIZE = [640, 480]

	class MainWin < Gtk::Window
		def initialize
			super(APP_NAME)
			self.set_default_size(*WINDOW_SIZE)

			self.signal_connect("delete_event") do
				Gtk.main_quit
			end
			self.signal_connect("key-press-event") do |w, e|
				if e.keyval == Gdk::Keyval::GDK_q
					Gtk.main_quit
				end
			end
		end
	end

	if ARGV.empty?
		puts "Usage: #{$0} <file>"
		exit(1)
	end
	unless File.exist?(ARGV[0])
		puts "#{$0}: #{ARGV[0]}: No such file"
		exit(1)
	end

	image = Gtk::Image.new(ARGV[0])
	width, height = image.pixbuf.width, image.pixbuf.height

	if width > WINDOW_SIZE[0] || height > WINDOW_SIZE[1]
		image.pixbuf = image.pixbuf.scale(*WINDOW_SIZE)
	end

	main_win = MainWin.new
	main_win.add(image)
	main_win.show_all
	Gtk.main
else
	raise NotImplementedError, "mode = #{mode}"
end
