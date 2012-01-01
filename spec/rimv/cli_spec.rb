require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*1, 'spec_helper.rb'].flatten))

describe Rimv::CLI do
	describe '.parse' do
		after :each do
			Rimv.mode = nil
		end

		describe '-a' do
			it 'should invoke add mode' do
				Rimv::CLI.parse %w<-a>
				include ::Rimv
				Rimv.mode.should == 'add'
			end
		end

		describe '--add' do
			it 'should invoke add mode' do
				Rimv::CLI.parse %w<--add>
				include ::Rimv
				Rimv.mode.should == 'add'
			end
		end

		describe '-v' do
			it 'should invoke view mode' do
				Rimv::CLI.parse %w<-v>
				include ::Rimv
				Rimv.mode.should == 'view'
			end
		end

		describe '--view' do
			it 'should invoke view mode' do
				Rimv::CLI.parse %w<--view>
				include ::Rimv
				Rimv.mode.should == 'view'
			end
		end
	end
end
