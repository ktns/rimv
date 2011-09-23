require 'gtk2'
require 'rimv/db/adaptor'
require 'rimv/keyval'

class Rimv::TagaddWin < Gtk::Window
	include Rimv::Keyval
	def initialize adaptor, parent
		raise TypeError unless adaptor.kind_of?(Rimv::DB::Adaptor)

		super 'Add a tag'

		self.signal_connect('key-press-event', &method(:keypress))

		add @vbox = Gtk::VBox.new
		@vbox.add @entry = Gtk::Entry.new
		@vbox.add @hbox  = Gtk::HBox.new
		@hbox.add @ok = Gtk::Button.new('OK')
		@hbox.add @cancel = Gtk::Button.new('Cancel')
		@entry.width_chars = adaptor.tags_max_length + 3
		@ok.signal_connect('clicked',&method(:ok))
		@cancel.signal_connect('clicked',&method(:cancel))
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

		set_modal(true)
		set_transient_for(@parent=parent)

		@ok.can_default=true
		@ok.grab_default
		@entry.activates_default=true

		show_all
	end

	def ok *args
		@parent.tagadd @entry.text
		cancel
	end

	def cancel *args
		destroy
	end

	def keypress widget, event
		if event.keyval == GDK_KEY_Escape
			cancel
		end
	end
end
