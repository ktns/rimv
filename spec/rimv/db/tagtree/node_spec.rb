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

require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*3, 'spec_helper.rb']))

describe Rimv::DB::TagTree::Node do
	before :each do
		@root_node = root_node
		@root_node.add('hoge', %w<a b>)
	end

	describe "['a', 'b'] and ['a']['b']" do
		it 'should be same' do
			expect(@root_node[*%w<a b>]).to equal @root_node['a']['b']
		end
	end
end
