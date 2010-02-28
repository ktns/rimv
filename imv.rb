#!/usr/bin/ruby
# vim: set foldmethod=syntax :
APP_NAME = "imv"

module IMV
	@@mode = nil
	@@path_tag = false
	@@random = false
	@@score = nil
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
	require "gtk2"

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
				db.execute(<<SQL, :hash => hash, :img => Blob.new(img), :score => @@score || 0)
INSERT INTO img (hash, img, score)
SELECT :hash, :img, :score
WHERE NOT EXISTS (SELECT 1 FROM img WHERE hash=:hash);
SQL
				db.execute(<<SQL, :hash => hash, :name => File.basename(name) )
INSERT INTO name (hash, name)
SELECT :hash, :name
WHERE NOT EXISTS (SELECT 1 FROM name WHERE hash=:hash AND name=:name);
SQL
			end and hash
		end

		def addfile path, base=false
			@base = path.sub(/\/*$/,'') if base
			begin
				if File.directory?(path)
					Dir.foreach(path) do |file|
						next if %w<. ..>.include?(file)
						verbose(1).puts "adding directory `#{path}/#{file}'"
						addfile("#{path}/#{file}")
					end
				elsif File.file?(path)
					img = Gtk::Image.new(path)
					if img.pixbuf || img.pixbuf_animation
						File.open(path) do |file|
							verbose(1).puts "adding file `#{path}'"
							hash = addimage(path,file.read)
							if @base
								verbose(3).puts "tag base = #{@base}"
								tag = File.dirname(path.sub(/^#{Regexp.escape(@base)}\/*/,''))
								unless tag == '.'
									addtag hash, tag
								end
							end
						end
					else
						$stderr.puts "`#{path}' is not a image supported by gtk!"
					end
				else
					$stderr.puts "file `#{path}' does not exist!"
				end
			ensure
				@base = nil if base
			end
		end

		def addtag hash, tag
			verbose(1).puts "tagging image `#{hash} as `#{tag}'"
			@db.execute(<<SQL, :hash => hash, :tag => tag)
INSERT INTO tag (hash, tag)
SELECT :hash, :tag
WHERE NOT EXISTS (SELECT 1 FROM tag WHERE hash=:hash AND tag = :tag);
SQL
		end

		def getimage_bin hash
					@db.execute(<<SQL,hash).collect.first.first
SELECT img
FROM img
WHERE hash = ?
LIMIT 1
SQL
		end

		def getimage hash
			require 'tempfile'
			tmp = Tempfile.new(APP_NAME)
			begin
				tmp.write getimage_bin(hash)
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

	class MainWin < Gtk::Window
		include IMV

		def initialize db, hash_list
			raise TypeError, "IMV::DB expected for `db', but #{db.class}" unless db.kind_of?(IMV::DB)
			raise TypeError, "Array expected for `hash_list', but #{hash_list.class}" unless hash_list.kind_of?(Array)

			super(APP_NAME)
			@db          = db
			@hash_list   = hash_list
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
				when Gdk::Keyval::GDK_r
					verbose(1).puts "#{@@random ? 'exit' :'enter'}ing random mode"
					@@random = ! @@random
				end
			end
			tmp_handler_id = signal_connect("window_state_event") do |w, e|
				if e.changed_mask == Gdk::EventWindowState::MAXIMIZED
					signal_handler_disconnect tmp_handler_id
					tmp_handler_id = signal_connect("configure_event") do
						@max_size = Size[size]
						verbose(1).puts "max size = #{@max_size}"
						signal_handler_disconnect tmp_handler_id
						unmaximize
						self.resizable = false
						display @hash_list[@cur_index = (
							@@random ? rand(@hash_list.size) : 0)]
					end
				end
			end
			show_all
			maximize
			@cur_img = nil
		end

		def cur_hash
			@hash_list[@cur_index]
		end

		def display hash
			remove(@cur_img) if @cur_img
			verbose(1).puts "displaying image with hash #{hash}"
			@cur_img = @db.getimage(hash)

			size_orig = Size[@cur_img.pixbuf]
			size_view = size_orig.fit(@max_size)
			verbose(2).puts "scaling img with size #{size_orig} to #{size_view}"

			@cur_img.pixbuf = @cur_img.pixbuf.scale(*size_view)
			add(@cur_img)
			resize(*size_view)
			set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
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
	begin
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
				raise "invalid verbosity `#{v}'!" unless @@verbosity > 0
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

			opt.on('-p', '--path-tag',
						 'tag image with directory name'){@@path_tag = true}

			opt.parse!
		end

		case @@mode
		when 'add'
			raise 'No file to add!' if ARGV.empty?
			raise "Non-integer score is not acceptable in `add' mode!" unless ! @@score || @@score.kind_of?(Integer)
			DB.open do |db|
				ARGV.each do |name|
					db.addfile(name, @@path_tag)
				end
			end
		when 'view',nil
			DB.open do |db|
				abort 'No Image!' if (hashlist = db.getallhash).empty?
				main_win = MainWin.new(db, hashlist)
				Gtk.main
			end
		else
			raise NotImplementedError, "Unexpected mode `#{mode}'!"
		end
	rescue Interrupt
	end
end
