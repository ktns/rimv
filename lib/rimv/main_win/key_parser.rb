class Rimv::MainWin
	class KeyParser
		include Rimv
		include Gdk::Keyval

		def initialize
			@stack = []
		end

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
				verbose(1).puts "#{@@random ? 'exit' :'enter'}ing random mode"
				@@random = ! @@random
			},
				[GDK_KEY_s, GDK_KEY_plus] => lambda {|w|
				w.score_up
			},
				[GDK_KEY_s, GDK_KEY_minus] => lambda {|w|
				w.score_down
			}
		}

		def has_chance?
			@@map.each_key.any? do |key|
				key[0...@stack.size] == @stack
			end
		end

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
