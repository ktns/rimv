#
# Copyright (C) Katsuhiko Nishimra 2010, 2011, 2012.
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

module Rimv
	class MainWin
		# This class represents a popup window to indicate tags of currently displayed image
		class TagPopup < Gtk::Window
			# Tells whether window is popped up
			def on?
				@on
			end

			# Toggles whether window is popped up
			def toggle
				@on = ! @on
				if @on
					show_all
				else
					hide
				end
			end

			# Creates new instance under MainWin
			def initialize main_win
				@on       = false
				@main_win = main_win

				super Gtk::Window::POPUP

				add(@label = Gtk::Label.new)
				set_allow_shrink false

				signal_connect('configure_event') do |w,e|
					move
				end
			end

			# Display tags of the Leaf
			def display leaf
				unless leaf.instance_of?(Rimv::DB::TagTree::Leaf)
					raise TypeError, 'expected Rimv::DB::TagTree::Leaf, but %s' %leaf.class
				end
				verbose(2).puts "tagpopup#display; path=#{leaf.path}"
				tags = leaf.path.collect{|n|n.tag}
				tags.shift
				tags << 'None' if tags.empty?
				@label.text = tags.join("\n")

				resize 1,1
				show_all if @on
			end

			# Move window to right bottom of the MainWin
			def move
				super(*(Size[@main_win.position]+Size[@main_win]-Size[size]))
			end
		end
	end
end
