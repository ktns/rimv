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
end
