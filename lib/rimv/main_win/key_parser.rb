class Rimv::MainWin
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
				}, [GDK_t,GDK_s] => lambda {|w|
					verbose(1).puts 'toggle tag popup window'
					w.tagpopup.toggle
					verbose(2).puts "tag popup is now #{w.tagpopup ? 'on' : 'off'}"
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
end
