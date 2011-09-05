require 'rimv/size'

module Rimv
	class MainWin < Gtk::Window
		include Rimv

		attr_reader :tagpopup

		def initialize adaptor
			raise TypeError, "Rimv::DB::Adaptor expected for `adaptor', but #{adaptor.class}" unless adaptor.kind_of?(Rimv::DB::Adaptor)

			super(APP_NAME)
			@adaptor       = adaptor
			@tree     = Rimv::DB::TagTree.new(adaptor.hashtags)
			@kparser  = KeyParser.new
			@tagpopup = TagPopup.new self

			self.title = APP_NAME + Version

			self.icon_list = Logo.icons
			self.icon      = Logo.icon(32)

			signal_connect("delete_event") do
				Gtk.main_quit
			end
			signal_connect("key-press-event") do |w, e|
				@kparser.send(w,e)
			end
			signal_connect("focus-out-event") do
				@tagpopup.hide if @tagpopup
			end
			signal_connect("focus-in-event") do
				@tagpopup.show if @tagpopup
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
					new_img = @adaptor.getimage(hash)
					@cur_img.pixbuf = new_img.pixbuf if new_img.pixbuf
					@cur_img.pixbuf_animation = new_img.pixbuf_animation if new_img.pixbuf_animation
				else
					add_img = true
					@cur_img = @adaptor.getimage(hash)
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

		# Let the user add a new tag on the current image
		def pop_tagadd_win
			TagaddWin.new(@adaptor, self)
		end

		# Add specified tag on current image
		def tagadd tag
			raise NotImplementedError
		end
	end
end

require 'rimv/main_win/key_parser'
require 'rimv/main_win/tagpopup'
require 'rimv/tagadd_win'
