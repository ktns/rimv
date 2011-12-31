require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*1, 'spec_helper.rb'].flatten))

describe Rimv::CLI do
	describe '.parse' do
		describe '-a' do
			it 'should invoke add mode' do
				Rimv::CLI.parse %w<-a>
				include ::Rimv
				Rimv.mode.should == 'add'
			end
		end
	end
end
