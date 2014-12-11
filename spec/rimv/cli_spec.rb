require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*1, 'spec_helper.rb'].flatten))

describe Rimv::CLI do
	describe '.parse' do
		describe '-a' do
			it 'should invoke add mode' do
				expect(Rimv::Application).to receive(:new).with('add', *[anything]*5)
				Rimv::CLI.parse %w<-a>
			end
		end

		describe '--add' do
			it 'should invoke add mode' do
				expect(Rimv::Application).to receive(:new).with('add', *[anything]*5)
				Rimv::CLI.parse %w<--add>
			end
		end

		describe '-v' do
			it 'should invoke view mode' do
				expect(Rimv::Application).to receive(:new).with('view', *[anything]*5)
				Rimv::CLI.parse %w<-v>
			end
		end

		describe '--view' do
			it 'should invoke view mode' do
				expect(Rimv::Application).to receive(:new).with('view', *[anything]*5)
				Rimv::CLI.parse %w<--view>
			end
		end
	end
end
