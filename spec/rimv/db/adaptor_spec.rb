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

require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*2, 'spec_helper.rb']))

describe Rimv::DB::Adaptor do
	describe '#addfile' do
		before :each do
			@file = File.join(asset_path, 'logo.png')
			@adaptor = MockAdaptor.new
		end

		it 'should invoke addimage' do
			expect(@adaptor).to receive(:addimage).with(@file, anything())
			@adaptor.addfile @file
		end

		context 'with tag ending with -' do
			it 'should invoke deltag' do
				allow(Rimv::Application).to receive(:tag).and_return(['hoge-'])
				expect(@adaptor).to receive(:deltag).with(anything(), 'hoge')
				@adaptor.addfile @file
			end
		end
	end

	describe '.getimage' do
		let(:adaptor) do
			MockAdaptor.new.tap do |adaptor|
				class <<adaptor
					def getimage_bin hash
						read_logo
					end
				end
			end
		end
		let(:hash){double('hash')}

		it 'should invoke getimage_bin' do
			expect(adaptor).to receive(:getimage_bin).exactly(1).times.
				with(hash).and_return(read_logo)
			adaptor.getimage hash
		end

		let(:image){adaptor.getimage hash}
		subject{image}

		it do
			is_expected.to be_instance_of Gtk::Image
		end

		describe '.pixbuf.pixels' do
			subject{image.pixbuf.pixels}
			it 'should be digested correctly' do
				expect(Rimv::DB.digest(subject)).to eq '74119156e0139f57c3cb2f38eafef303'
			end
		end

		context 'with truncated binary' do
			let(:adaptor) do
				MockAdaptor.new.tap do |adaptor|
					class <<adaptor
						def getimage_bin hash
							bin = read_logo
							return bin[0..bin.size-30]
						end
					end
				end
			end

			it do
				is_expected.to be_instance_of Gtk::Image
			end
		end
	end
end
