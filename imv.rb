#!/usr/bin/ruby
# vim: set foldmethod=syntax :
APP_NAME = "imv"

module IMV
	@@mode = nil
	@@score = nil
	@@random = false
	@@verbosity = 0

	class DummyIO
		def method_missing name, *arg
			unless IO.method_defined?(name)
				raise NoMethodError.new("method `#{name}' is undefined in IO class!", name, arg)
			end
		end
	end

	def verbose verbosity
		raise ScriptError, "invalid verbosity `#{num}'!" unless verbosity > 0
		if verbosity <= @@verbosity
			$stdout
		else
			DummyIO.new
		end
	end

	class DB
		include IMV

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
									 Blob.new(img), @@score || 0)
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
					verbose(1).puts "adding directory `#{path}/#{file}'"
					addfile("#{path}/#{file}")
				end
			elsif File.file?(path)
				File.open(path) do |file|
					verbose(1).puts "adding file `#{path}'"
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
			where,arg =
				case @@score
				when nil
					['',[]]
				when Integer
					['WHERE score = ?', [@@score]]
				when Range
					['WHERE score BETWEEN ? AND ?', [@@score.begin, @@score.last]]
				else
					raise ScriptError
				end
			@db.execute(<<"SQL", *arg).collect {|set| set.first}
SELECT hash
FROM img
#{where}
SQL
		end
	end

	class Size
		attr_accessor :width, :height

		def initialize width, height
			@width, @height = [width, height].collect &:to_i
		end

		def self.[] *arg
			case arg.size
			when 1
				arg = arg.first
				if arg.kind_of?(Array)
					self.new(*arg)
				else
					self.new(arg.width, arg.height)
				end
			when 2
				self.new(arg.first,arg.last)
			else
				raise ArgumentError, "#{arg.size} arguments is not supported!"
			end
		end

		def to_a
			[@width, @height]
		end

		def to_s
			"[#{@width},#{@height}]"
		end

		def == other
			other.kind_of?(self.class) and
			@width == other.width && @height == other.height
		end

		def op_for_both other, &block
			case other
			when Size
				Size.new(*([[@width, other.width],
								 [@height, other.height]].collect &block))
			when Array
				self - Size.new(*other)
			else
				raise TypeError, "Invalid class `#{other.class}'!"
			end
		end
		private :op_for_both

		def + other
			op_for_both(other){|s,o| s + o}
		end

		def - other
			op_for_both(other){|s,o| s - o}
		end

		def * other
			Size.new(@width * other, @height * other)
		end

		def / other
			Size.new(@width / other, @height / other)
		end

		def abs
			Size.new(@width.abs, @height.abs)
		end

		def fit frame
			ratio = [frame.width.to_f/@width,frame.height.to_f/@height].min
			Size[@width * ratio, @height *ratio]
		end
	end

	require "gtk2"
	class MainWin < Gtk::Window
		include IMV

		def initialize db, hash_list
			raise TypeError, "IMV::DB expected for `db', but #{db.class}" unless db.kind_of?(IMV::DB)
			raise TypeError, "Array expected for `hash_list', but #{hash_list.class}" unless hash_list.kind_of?(Array)

			super(APP_NAME)
			set_default_size(*WINDOW_SIZE)
			@db = db
			@hash_list = hash_list
			@random_hist = []

			signal_connect("delete_event") do
				Gtk.main_quit
			end
			signal_connect("key-press-event") do |w, e|
				case e.keyval
				when Gdk::Keyval::GDK_q
					Gtk.main_quit
				when Gdk::Keyval::GDK_space
					display_next
				when Gdk::Keyval::GDK_BackSpace
					display_prev
				end
			end
			@cur_img = nil
			display @hash_list[@cur_index = (
				@@random ? rand(@hash_list.size) : 0)]
		end

		def cur_hash
			@hash_list[@cur_index]
		end

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
			unless @@random
				display(@hash_list[@cur_index = ((@cur_index+1) % @hash_list.length)])
			else
				display_random
			end
		end

		def display_prev
			unless @@random
				display(@hash_list[@cur_index = ((@cur_index-1) % @hash_list.length)])
			else
				hist = @random_hist.pop
				if hist
					display hist
				else
					display_random
				end
			end
		end

		def display_random
			@random_hist.push cur_hash
			begin
				next_index = rand(@hash_list.size)
			end until next_index != @cur_index
			display(@hash_list[@cur_index = next_index])
		end
	end
end

if $0 == __FILE__
	include IMV

	require 'optparse'


	ARGV.options do |opt|
		MODES={
			'add'=>'add image(s) to database',
			'view'=>'view images in database'
		}.each do |mode,desc|
			opt.on('-'+mode[0,1],'--'+mode,desc) do |v|
				if @@mode
					$stderr.printf("multiple mode option specified!('%s' after '%s')\n",
												 mode, @@mode)
					abort
				else
					@@mode = mode
				end
			end
		end
		opt.on('--verbose=[VERBOSITY]', 'verbosely report information') do |v|
			@@verbosity = v.nil? ? 1 : v.to_i
			verbose(1).puts "verbosity = #{@@verbosity}"
		end

		opt.on('-s=VAL', '--score=VAL',
					 'score of the image to be displayed or added') {|val|
			if val =~ /\A(-?d+)([+-])\Z/
				if $2 == '+'
					@@score = (eval $1)..1.0/0
				else
					@@score = -1.0/0..(eval $1)
				end
			else
				@@score = eval val
				unless [Integer,Range].any?{|cls| @@score.kind_of?(cls)}
					raise ArgumentError, "Can't parse score value string `#{val}'!"
				end
			end
		}

		opt.on('-r', '--random',
					 'randomize order of images to be displayed'){@@random=true}

		opt.parse!
	end

	case @@mode
	when 'add'
		raise 'No file to add!' if ARGV.empty?
		raise "Non-integer score is not acceptable in `add' mode!" unless ! @@score || @@score.kind_of?(Integer)
		DB.open do |db|
			ARGV.each do |name|
				db.addfile(name)
			end
		end
	when 'view',nil
		WINDOW_SIZE = [640, 480]

		DB.open do |db|
			abort 'No Image!' if (hashlist = db.getallhash).empty?
			main_win = MainWin.new(db, hashlist)
			Gtk.main
		end
	else
		raise NotImplementedError, "Unexpected mode `#{mode}'!"
	end
end
