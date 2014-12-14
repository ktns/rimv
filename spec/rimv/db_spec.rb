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

describe Rimv::DB do
	describe '.digest' do
		subject {Rimv::DB.digest(IO.read(File.join(asset_path,'logo.png')))}

		it 'should return String' do
			is_expected.to be_kind_of String
		end
	end

	shared_examples_for 'acceptable' do |tag|
		subject{Rimv::DB.acceptable_tag?(tag)}
		it 'should return true' do
			is_expected.to be_truthy
		end
	end

	shared_examples_for 'unacceptable' do |tag|
		subject{Rimv::DB.acceptable_tag?(tag)}
		it 'should return false' do
			is_expected.to be_falsey
		end
	end

	describe '.acceptable_tag?' do
		for tag in %w<hoge ho.ge ho/ge h0.ge h0ge>
			describe("\b(#{tag})") do
				it_should_behave_like 'acceptable', tag
			end
		end

		for tag in %w<hoge/ /hoge h0ge\  ho,ge hoge,>
			describe("\b(#{tag})") do
				it_should_behave_like 'unacceptable', tag
			end
		end
	end
end
