require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*1, 'spec_helper.rb'].flatten))

describe Rimv::MainWin do
	describe 'without initialization' do
		class TestMainWin < Rimv::MainWin
			def initialize adaptor
				@adaptor=adaptor
			end
		end

		before :each do
			@win=TestMainWin.new @adaptor=MockAdaptor.new
		end

		it '#tagadd should invoke Adaptor#tagadd' do
			tag=stub(:tag)
			@win.stub!(:cur_hash).and_return(cur_hash=stub(:cur_hash))
			@adaptor.should_receive(:addtag).with(cur_hash, tag)
			@win.tagadd tag
		end
	end
end
