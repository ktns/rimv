require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*1, 'spec_helper.rb'].flatten))

describe Rimv::TagaddWin do
	before :each do
		@win=Rimv::TagaddWin.new MockAdaptor.new, @parent=Gtk::Window.new
	end

	it 's ok should invoke MainWin#addtag' do
		class <<@win
			attr_reader :entry
		end
		@win.entry.should_receive(:text).and_return :tag_to_be_added
		@parent.should_receive(:addtag).with(:tag_to_be_added)
		@win.ok
	end

	#after :each do
	#	while Gtk.events_pending?
	#		Gtk.main_iteration
	#	end
	#end
end