#
# Copyright (C) Katsuhiko Nishimra 2011, 2012, 2014.
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

require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*1, 'spec_helper.rb']))

describe Rimv::TagaddWin do
	before :each do
		@win=Rimv::TagaddWin.new @adaptor=MockAdaptor.new, @parent=Gtk::Window.new
	end

	it 's ok should invoke MainWin#addtag' do
		entry=@win.entries.first
		expect(entry).to receive(:text).and_return :tag_to_be_added
		expect(@parent).to receive(:addtag).with(:tag_to_be_added)
		@win.ok
	end

	#after :each do
	#	while Gtk.events_pending?
	#		Gtk.main_iteration
	#	end
	#end
end
