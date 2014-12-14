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

describe Rimv::MainWin do
	describe 'without initialization' do
		class TestMainWin < Rimv::MainWin
			def initialize adaptor
				@adaptor=adaptor
			end
		end

		before :each do
			@win=TestMainWin.new @adaptor=MockAdaptor.new
		end

		it '#addtag should invoke Adaptor#addtag' do
			tag=double(:tag)
			allow(@win).to receive(:cur_hash).and_return(cur_hash=double(:cur_hash))
			expect(@adaptor).to receive(:addtag).with(cur_hash, tag)
			@win.addtag tag
		end
	end
end
