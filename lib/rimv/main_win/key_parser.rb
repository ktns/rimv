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

require 'rimv/keyval'

class Rimv::MainWin
	# KeyParser class for MainWin
	class KeyParser
		include Rimv
		include Rimv::Keyval

		# Creates new KeyParser
		def initialize
			@stack = []
		end

		# Keymap
		@@map = {
			[GDK_KEY_q] =>
			lambda {|w|
				Gtk.main_quit
			}, [GDK_KEY_h] =>
			lambda {|w|
				w.hide
				Thread.new(w) do |w|
					puts 'press enter to reshow window...'
					$stdin.gets
					w.show
				end
			}, [GDK_KEY_space] => lambda {|w|
				w.display_next
			}, [GDK_KEY_BackSpace] => lambda {|w|
				w.display_prev
			}, [GDK_KEY_r] => lambda {|w|
				verbose(1).puts "#{Application.random ? 'exit' :'enter'}ing random mode"
				Application.random = ! Application.random
			}, [GDK_KEY_t,GDK_KEY_s] => lambda {|w|
					verbose(1).puts 'toggle tag popup window'
					w.tagpopup.toggle
					verbose(2).puts "tag popup is now #{w.tagpopup ? 'on' : 'off'}"
			},
#				[GDK_KEY_s, GDK_KEY_plus] => lambda {|w|
#				w.score_up
#			},
#				[GDK_KEY_s, GDK_KEY_minus] => lambda {|w|
#				w.score_down
			[GDK_KEY_t, GDK_KEY_a] => lambda {|w|
						w.pop_tagadd_win
			}
		}

		# Tells whether stacked key strokes have chance to be a part of command
		def has_chance?
			@@map.each_key.any? do |key|
				key[0...@stack.size] == @stack
			end
		end

		# Gtk event handler
		def send w, e
			@stack << e.keyval
			if handler = @@map[@stack]
				handler.call w
			elsif has_chance?
				verbose(2).puts "KeyParser pending; stack = #{@stack.pack('c*')}"
				return @stack
			end
			@stack = []
		end
	end
end
