module Rimv
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

		attr_reader :tagpopup

		def initialize db
			raise TypeError, "Rimv::DB expected for `db', but #{db.class}" unless db.kind_of?(Rimv::DB)

			super(APP_NAME)
			@db       = db
			@tree     = Rimv::DB::TagTree.new(db)
			@kparser  = KeyParser.new
			@tagpopup = TagPopup.new self

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
						signal_connect("configure_event") do |w, e|
							verbose(2).puts('mainwin#configure_event')
							@tagpopup.move
							print ''
						end
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
				@tagpopup.display hash
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

require 'rimv/main_win/key_parser'
require 'rimv/main_win/tagpopup'
