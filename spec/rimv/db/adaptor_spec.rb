require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*2, 'spec_helper.rb'].flatten))

describe Rimv::DB::Adaptor do
	describe 'addfile' do
		before :each do
			@file = File.join(asset_path, 'logo.png')
			@adaptor=mock('adaptor')
			@adaptor.extend Rimv::DB::Adaptor
		end

		it 'should invoke addimage' do
			@adaptor.should_receive(:addimage).with(@file, anything())
			@adaptor.addfile @file
		end
	end

	describe '.getimage' do
		before :all do
			@adaptor=stub('adaptor').extend(Rimv::DB::Adaptor)
			@hash=stub('hash')
			class <<@adaptor
				def getimage_bin hash
					read_logo
				end
			end
		end

		it 'should invoke getimage_bin' do
			@adaptor.should_receive(:getimage_bin).exactly(1).times.
				with(@hash).and_return(read_logo)
			@adaptor.getimage @hash
		end

		subject {@adaptor.getimage @hash}

		it do
			should be_instance_of Gtk::Image
		end

		its("pixbuf.pixels") do
			Rimv::DB.digest(subject).should eq '74119156e0139f57c3cb2f38eafef303'
		end

		context 'with truncated binary' do
			before :all do
				@adaptor=@adaptor.clone
				class <<@adaptor
					def getimage_bin hash
						bin = read_logo
						return bin[0..bin.size-30]
					end
				end
			end

			it do
				should be_instance_of Gtk::Image
			end
		end
	end
end
