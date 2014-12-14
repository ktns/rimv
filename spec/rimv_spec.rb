#
# Copyright (C) Katsuhiko Nishimra 2010, 2011, 2012, 2014.
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

require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*0, 'spec_helper.rb']))

describe 'blank_db' do
	it 'should be accessible' do
		require 'fileutils'
		FileUtils.touch blank_db
	end
end

describe 'asset_path' do
	it 'should be an existing directory' do
		expect(FileTest.directory?(asset_path)).to be_truthy
	end

	it 'should include file `logo.png\'' do
		expect(FileTest.exist?(File.join(asset_path, 'logo.png'))).to be_truthy
	end
end
