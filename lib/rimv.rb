$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Rimv
	APP_NAME = "imv"
  VERSION = '0.0.1'

	require "gtk2"

	@@mode      = nil
	@@path_tag  = false
	@@tag       = nil
	@@random    = false
	@@score     = nil
	@@verbosity = 0

	module Logo
		@@base  = Gdk::Pixbuf.new(File.dirname(__FILE__) + '/../asset/logo.xpm')
		@@sizes = Hash[
			*([8,16,32,64].collect do |size|
				[size, @@base.scale(size, size)]
			end.flatten)
		]

		def self.icons
			@@sizes.values
		end

		def self.icon size
			@@sizes[size]
		end
	end

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
		include Rimv

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
				begin
					db.close
				rescue SQLite3::BusyException
					$stderr.puts 'Aborting running query!'
				end
			end
		end

		@@db_file = "#{ENV['HOME']}/.imv.sqlite3"

		def self.db_file
			@@db_file
		end

		def self.db_file= db_file
			@@db_file = db_file
		end

		def initialize
			@db = Database.new(self.class.db_file)
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
							elsif @@tag
								verbose(3).puts "tagging `#{path}'(#{hash}) as `#{@@tag}'"
								addtag hash, @@tag
							end
						end
					else
						$stderr.puts "`#{path}' is not a image supported by gtk!"
						verbose(2).puts "image            = #{img.inspect}"
						verbose(2).puts "pixbuf           = #{img.pixbuf.inspect}"
						verbose(2).puts "pixbuf_animation = #{img.pixbuf_animation.inspect}"
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

		def each_hash_tags
			@db.execute(<<SQL) {|hash, tags| yield hash, (tags||'').split('|').uniq}
SELECT img.hash, group_concat(tag,'|')
FROM (img LEFT JOIN tag ON img.hash = tag.hash)
	LEFT JOIN name ON img.hash = name.hash
GROUP BY img.hash
ORDER BY min(name.name)
SQL
		end

		class TagTree
			include Rimv

			class Node
				include Rimv
				attr_reader :parent, :tag, :children, :hashes

				def <=> other
					raise TypeError unless other.kind_of?(self.class)
					raise ArgumentError,
						'Comparing TagTree::Nodes having different parent!' unless @parent == other.parent
					raise 'Comparing root nodes does not make sense!' unless @parent
					tag <=> other.tag
				end

				def path
					path = []
					node = self
					while node
						path.unshift node
						node = node.parent
					end
					return path
				end

				def tags
					path.collect{|n| n.tag}.compact
				end

				def to_s
					path.collect{|node| node.tag or 'ROOT'}.join('->')
				end

				def inspect
					"#<#{self.class.name};#{to_s}>"
				end

				def initialize parent, tag
					verbose(4).puts 'Initializing new TagTree Node; ' +
						"parent=#{parent ? parent.to_s : 'none'}, tag = #{tag}"
					[
						[parent,self.class],
						[tag,String]
					].each do |v,c|
						unless v == nil || v.kind_of?(c)
							raise TypeError "`#{c}' expected, but `#{v.class}'"
						end
					end
					@parent, @tag = parent, tag
					@children     = []
					@hashes       = []
				end

				def consistent? depth = 0
					verbose(1).puts "Consistency Check for tag #{@tag}, depth #{depth}"
					@children.each do |c|
						unless c.parent == self
							raise "TagTree consistency Error! tag = #{@tag}, depth = #{depth}"
							return false
						end
						raise unless c.consistent?(depth+1) == true
					end
					true
				end

				class Leaf
					attr_reader :node

					def initialize hash, node
						raise TypeError, "String expected, but `#{hash.class}'" unless hash.instance_of?(String)
						raise TypeError, "Rimv::DB::TagTree::Node expected, but `#{node.class}'" unless node.instance_of?(Rimv::DB::TagTree::Node)
						@hash = hash
						@node = node
					end

					def to_s
						@hash
					end

					def === other
						@hash == other.to_s
					end

					def == other
						@hash == other.to_s and node == other.node
					end

					def eql? other
						@hash.eql? other.to_s and node.eql? other.node
					end

					def hash
						[@hash, @node].hash
					end

					def inspect
						"#<#{self.class.name};#{@node.to_s}->#{to_s}>"
					end

					def path
						@node.path
					end

					def tags
						@node.tags
					end

					def next
						@node.next_hash_of self
					end

					def prev
						@node.prev_hash_of self
					end
				end

				def add hash, tags
					verbose(4).puts "adding hash `#{hash}' into TagTree; " +
						"tagstack [#{tags.join(', ')}]"
					if tags.empty?
						new_leaf = Leaf.new(hash, self)
						raise "Duplicate leaf #{new_leaf} added to #{self}" if @hashes.include? new_leaf
						@hashes.push new_leaf
					else
						tags.each do |tag|
							unless child = @children.find{|c|c.tag == tag}
								@children.push(child = self.class.new(self, tag))
								@children.sort!
							end
							raise "#{self.class} expected, but #{child.class}!" unless child.class == self.class
							child.add(hash, tags.reject{|t| t == tag})
						end
					end
				end

				def first
					@hashes.first or @children.first.first or
					raise "#{inspect}.first returned nil"
				end

				def next_hash_of hash
					@hashes[@hashes.index(hash)+1] or
					if @children.empty?
						@parent.next_node_of(self).first
					else
						@children.first.first
					end
				end

				def next_node_of node
					@children[@children.index(node)+1] or
					if @parent
						@parent.next_node_of(self)
					else
						self
					end
				end

				def last_hash
					@hashes.last
				end

				def last_node
					if @children.empty?
						self
					else
						@children.last.last_node
					end
				end

				def prev_hash_of hash
					if (index = @hashes.index(hash)-1) >= 0
						@hashes[index]
					else
						if @parent
							node = self
							begin
								node = node.parent.prev_node_of(node)
							end until node.last_hash
							node.last_hash
						else
							last_node.last_hash
						end
					end
				end

				def prev_node_of node
					if ( index = @children.index(node)-1 ) >= 0
						@children[index].last_node
					else
						self
					end
				end

				def each_leaves &block
					raise ArgumentError, 'each_leaves called without block!' unless block.kind_of?(Proc)
					@hashes.each &block
					@children.each do |c|
						c.each_leaves &block
					end
				end

				def leaves
					Enumerable::Enumerator.new(self, :each_leaves)
				end

				def each_nodes &block
					raise ArgumentError, 'each_nodes called without block!' unless block.kind_of?(Proc)
					yield self
					@children.each do |c|
						c.each_nodes &block
					end
				end

				def nodes
					Enumerable::Enumerator.new(self, :each_nodes)
				end

				def shuffle tags
					if tags.empty?
						self
					else
						tags.collect do |tag|
							@children.find{|c| c.tag == tag}.shuffle tags - [tag]
						end.flatten
					end
				end
			end

			def sync
				@mutex.lock
				begin
					return yield
				ensure
					@mutex.unlock
				end
			end

			attr_reader :current

			def initialize db
				verbose(2).puts 'Initializing TagTree...'
				raise unless db.kind_of?(Rimv::DB)
				@mutex       = Mutex.new
				@root        = Node.new(nil, nil)
				@random_hist = []
				@thread = Thread.new do
					Thread.current.abort_on_exception = true
					db.each_hash_tags do |hash, tags|
						sync do
							@root.add hash, tags
						end
					end
				end
				verbose(3).puts 'Waiting for first leaf to be added...'
				Thread.pass until sync {leaves.count > 0}
				@current = first
				verbose(3).puts 'First leaf has now been added.'
			end

			def loading?
				@thread.alive?
			end

			def wait_until_loading
				@thread.join
			end

			def consistent?
				sync do
					@root.consistent?
				end
			end

			def first
				sync do
					@current = @root.first
				end
			end

			def next
				sync do
					@current = @current.next
				end
			end

			def prev
				sync do
					@current = @current.prev
				end
			end

			def last
				sync do
					@root.last
				end
			end

			def random
				sync do
					@random_hist.push @current
					@current = leaves.entries[rand(leaves.count)]
				end
			end

			def random_prev
				sync do
					@current = @random_hist.pop
				end || random
			end

			def each_leaves &block
				sync do
					@root.each_leaves &block
				end
			end

			def leaves
				@root.leaves
			end

			def each_nodes &block
				sync do
					@root.each_nodes &block
				end
			end

			def nodes
				@root.nodes
			end

			def isotopes item
				node = item.instance_of?(Node::Leaf) ? item.node : item
				raise ArgumentError, "#{Node} expected, but #{node.class}" unless
					node.instance_of?(Node)
				isotopes = @root.shuffle item.path.collect{|node| node.tag}.compact
				case item
				when Node
					isotopes
				when Node::Leaf
					isotopes.collect do |i|
						i.hashes.find{|h| h.to_s == item.to_s}
					end
				else
					raise
				end
			end
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
				elsif arg.respond_to?(:size)
					self.new(*arg.size)
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
		include Rimv

		class KeyParser
			include Rimv
			include Gdk::Keyval

			def initialize
				@stack = []
			end

			@@map = {
				[GDK_q] =>
				lambda {|w|
					Gtk.main_quit
				}, [GDK_h] =>
				lambda {|w|
					w.hide
					Thread.new(w) do |w|
						puts 'press enter to reshow window...'
						$stdin.gets
						w.show
					end
				}, [GDK_space] => lambda {|w|
					w.display_next
				}, [GDK_BackSpace] => lambda {|w|
					w.display_prev
				}, [GDK_r] => lambda {|w|
					verbose(1).puts "#{@@random ? 'exit' :'enter'}ing random mode"
					@@random = ! @@random
				}
			}

			def have_chance?
				@@map.each_key.any? do |key|
					key[0...@stack.size] == @stack
				end
			end

			def send w, e
				@stack << e.keyval
				if handler = @@map[@stack]
					handler.call w
				elsif have_chance?
					verbose(2).puts "KeyParser pending; stack = #{@stack.pack('c*')}"
					return @stack
				end
				@stack = []
			end
		end

		def initialize db
			raise TypeError, "Rimv::DB expected for `db', but #{db.class}" unless db.kind_of?(Rimv::DB)

			super(APP_NAME)
			@db      = db
			@tree    = Rimv::DB::TagTree.new(db)
			@kparser = KeyParser.new

			self.icon_list = Logo.icons
			self.icon      = Logo.icon(32)

			signal_connect("delete_event") do
				Gtk.main_quit
			end
			signal_connect("key-press-event") do |w, e|
				@kparser.send(w,e)
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
						display (@@random ? @tree.random : @tree.first)
					end
				end
			end
			show_all
			maximize
			@cur_img = nil
			verbose(2).puts 'waiting max image size to be retrieved...'
			Gtk.main_iteration until @max_size
			verbose(2).puts 'max image size was retrieved.'
		end

		def cur_hash
			@tree.current
		end

		def display hash
			verbose(1).puts "displaying image with hash #{hash}"
			window.cursor = Gdk::Cursor.new(Gdk::Cursor::WATCH)
			begin
				if @cur_img
					10.times {Gtk.main_iteration if Gtk.events_pending?}
					add_img = false
					new_img = @db.getimage(hash)
					@cur_img.pixbuf = new_img.pixbuf if new_img.pixbuf
					@cur_img.pixbuf_animation = new_img.pixbuf_animation if new_img.pixbuf_animation
				else
					add_img = true
					@cur_img = @db.getimage(hash)
				end

				raise ScriptError, "image has neither pixbuf or pixbuf_animation!\nhash=`#{hash}'" unless @cur_img.pixbuf || @cur_img.pixbuf_animation
				size_orig = Size[@cur_img.pixbuf || @cur_img.pixbuf_animation]
				size_view = size_orig.fit(@max_size)
				verbose(2).puts "scaling img with size #{size_orig} to #{size_view}"

				if @cur_img.pixbuf_animation
					@cur_img.pixbuf_animation
				elsif @cur_img.pixbuf
					@cur_img.pixbuf = @cur_img.pixbuf.scale(*size_view)
				else
					raise ScriptError, "image has neither pixbuf or pixbuf_animation!\nhash=`#{hash}'"
				end
				add(@cur_img) if add_img
				resize(*size_view)
				set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
				show_all
			ensure
				window.cursor = nil
			end
		end

		def display_next
			unless @@random
				display(@tree.next)
			else
				display(@tree.random)
			end
		end

		def display_prev
			unless @@random
				display(@tree.prev)
			else
				display(@tree.random_prev)
			end
		end
	end
end
