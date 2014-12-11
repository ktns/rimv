require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*1, 'spec_helper.rb']))

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

		it '#addtag should invoke Adaptor#addtag' do
			tag=double(:tag)
			allow(@win).to receive(:cur_hash).and_return(cur_hash=double(:cur_hash))
			expect(@adaptor).to receive(:addtag).with(cur_hash, tag)
			@win.addtag tag
		end
	end
end
