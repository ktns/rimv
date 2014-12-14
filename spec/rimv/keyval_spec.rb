#
# Copyright (C) Katsuhiko Nishimra 2012, 2014.
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

describe 'A module including Rimv::Keyval' do
	before :all do
		@module = Module.new do
			include Rimv::Keyval
		end
	end

	describe '.const_get' do
		subject{lambda {@module.const_get(@const_name)}}

		context 'with GDK_KEY_q' do
			before :all do
				@const_name = 'GDK_KEY_q'
			end

			it {is_expected.not_to raise_error}
		end

		context 'with undefined constant name' do
			before :all do
				@const_name = 'HOGE'
			end

			it {is_expected.to raise_error NameError}
		end
	end
end
