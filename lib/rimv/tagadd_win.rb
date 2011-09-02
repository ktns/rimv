require 'gtk2'

class Rimv::TagaddWin < Gtk::Window
	def initialize
		super 'Add a tag'
		add @vbox = Gtk::VBox.new
		@vbox.add @entry = Gtk::Entry.new
		@vbox.add @hbox  = Gtk::HBox.new
		@hbox.add @ok = Gtk::Button.new('OK')
		@hbox.add @cancel = Gtk::Button.new('Cancel')
		@vbox.show_all
		@ok.signal_connect('clicked',&method(:ok))
		@cancel.signal_connect('clicked',&method(:cancel))
		#@ok.grab_default
	end

	def ok *args
		#TODO: Add a tag
		cancel
	end

	def cancel *args
		hide
	end
end
