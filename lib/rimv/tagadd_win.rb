require 'gtk2'
require 'rimv/db/adaptor'

class Rimv::TagaddWin < Gtk::Window
	def initialize adaptor
		super 'Add a tag'
		raise TypeError unless adaptor.kind_of?(Rimv::DB::Adaptor)
		add @vbox = Gtk::VBox.new
		@vbox.add @entry = Gtk::Entry.new
		@vbox.add @hbox  = Gtk::HBox.new
		@hbox.add @ok = Gtk::Button.new('OK')
		@hbox.add @cancel = Gtk::Button.new('Cancel')
		@entry.width_chars = adaptor.tags_max_length + 3
		@vbox.show_all
		@ok.signal_connect('clicked',&method(:ok))
		@cancel.signal_connect('clicked',&method(:cancel))
		#@ok.grab_default
		set_resizable false

		completion = Gtk::EntryCompletion.new
		@entry.set_completion(completion)
		liststore=Gtk::ListStore.new(String)
		liststore.set_sort_column_id(0, Gtk::SORT_ASCENDING)
		completion.set_text_column(0)
		completion.model = liststore
		adaptor.tags.each do |tag|
			liststore.append.set_value(0,tag.to_s)
		end
	end

	def ok *args
		#TODO: Add a tag
		cancel
	end

	def cancel *args
		hide
	end
end
