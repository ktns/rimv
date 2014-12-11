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
			before :each do
				module Rimv
					@@tag = ['hoge-']
				end
			end

			it 'should invoke deltag' do
				expect(@adaptor).to receive(:deltag).with(anything(), 'hoge')
				@adaptor.addfile @file
			end

			after :each do
				module Rimv
					@@tag = []
				end
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
