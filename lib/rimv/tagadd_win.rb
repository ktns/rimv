require 'gtk2'
require 'rimv/db/adaptor'
require 'rimv/keyval'

# This class represents a window for tag addition.
class Rimv::TagaddWin < Gtk::Window
	include Rimv::Keyval
	# Creates a new window instance
	def initialize adaptor, parent
		raise TypeError unless adaptor.kind_of?(Rimv::DB::Adaptor)
		@adaptor=adaptor

		super 'Add a tag'

		self.signal_connect('key-press-event', &method(:keypress))

		add @vbox = Gtk::VBox.new
		@vbox.add @entries = Gtk::VBox.new
		@entries.add Gtk::Entry.new
		@vbox.add @hbox  = Gtk::HBox.new
		@hbox.add @ok = Gtk::Button.new('OK')
		@hbox.add @cancel = Gtk::Button.new('Cancel')
		@ok.signal_connect('clicked',&method(:ok))
		@cancel.signal_connect('clicked',&method(:cancel))
		set_resizable false

		@entry_width_chars = @adaptor.tags_max_length + 3

		@completion = Gtk::EntryCompletion.new
		liststore=Gtk::ListStore.new(String)
		liststore.set_sort_column_id(0, Gtk::SORT_ASCENDING)
		@completion.set_text_column(0)
		@completion.model = liststore
		@adaptor.tags.each do |tag|
			liststore.append.set_value(0,tag.to_s)
		end

		set_modal(true)
		set_transient_for(@parent=parent)

		@ok.sensitive   = false
		@ok.can_default = true
		@ok.grab_default
		entries do |entry|
			initialize_entry entry
		end

		show_all
	end

	# Initialize a new Entry
	def initialize_entry entry
			entry.width_chars = @entry_width_chars
			entry.signal_connect('changed',&method(:changed))
			entry.signal_connect('key-press-event',&method(:keypress_entry))
			entry.set_completion(@completion)
			entry.activates_default = true
	end

	# Returns entries for tag input
	def entries &block
		if block
			@entries.each &block
		else
			@entries.children
		end
	end

	# Event handler for ok button
	def ok *args
		entries do |entry|
			@parent.addtag entry.text
		end
		cancel
	end

	# Event handler for cancel button
	def cancel *args
		destroy
	end

	# Event handler for keypress event sent to TagaddWin
	def keypress widget, event
		if event.keyval == GDK_KEY_Escape
			cancel
		end
	end

	# Event handler for keypress event sent to Entry
	def keypress_entry widget, event
		if widget.text == '' and event.keyval == GDK_KEY_BackSpace
			if entries.count==1
				cancel
			else
				(@entries.children[@entries.children.index(widget)-1] or
				 @entries.children.first).grab_focus
				widget.destroy
				changed nil
			end
		end
	end

	# Event handler for text change event on an entry
	def changed widget
		splitted=entries.find do |entry|
			entry.text=~/#{Rimv::DB::TAG_CHARS}+,#{Rimv::DB::TAG_CHARS}/
		end
		if splitted
			newentry=Gtk::Entry.new
			splitted.text=splitted.text.sub(/,(#{Rimv::DB::TAG_CHARS}+)/,'')
			newentry.text=$1
			@entries.add newentry
			initialize_entry newentry
			newentry.grab_focus
			newentry.position=-1
			newentry.show
			@ok.grab_default
		end
		@ok.sensitive=entries.all?{|entry|Rimv::DB.acceptable_tag? entry.text}
	end
end
