#
# Copyright (C) Katsuhiko Nishimra 2010, 2011, 2012, 2014.
#
# This file is part of rimv.
#
# rimv is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Foobar is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

require 'rimv/size'

module Rimv
	# This class represents the main window of the application.
	class MainWin < Gtk::Window
		include Rimv

		# Tag indicator popup window
		attr_reader :tagpopup

		# Creates a new main window with the specified DB::Adaptor
		def initialize adaptor
			raise TypeError, "Rimv::DB::Adaptor expected for `adaptor', but `#{adaptor.class}'" unless adaptor.kind_of?(Rimv::DB::Adaptor)

			super(APP_NAME + Version)
			@adaptor  = adaptor
			@tree     = Rimv::DB::TagTree.new(adaptor.hashtags)
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
						display (Application.random ? @tree.random : @tree.first)
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

		# Returns a TagTree::Leaf currently displayed
		def cur_hash
			@tree.current
		end

		# Displays an image specified by a TagTree::Leaf
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

		# Displays an image specified with the next TagTree::Leaf of the current TagTree::Leaf
		def display_next
			unless Application.random
				display(@tree.next)
			else
				display(@tree.random)
			end
		end

		# Displays an image specified with the previous TagTree::Leaf of the current TagTree::Leaf
		def display_prev
			unless Application.random
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
		def addtag tag
			@adaptor.addtag cur_hash, tag
		end
	end
end

require 'rimv/main_win/key_parser'
require 'rimv/main_win/tagpopup'
require 'rimv/tagadd_win'
