module Rimv
	class MainWin
		class TagPopup < Gtk::Window
			def on?
				@on
			end

			def toggle
				@on = ! @on
				if @on
					show_all
				else
					hide
				end
			end

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

			def move
				super(*(Size[@main_win.position]+Size[@main_win]-Size[size]))
			end
		end
	end
end
