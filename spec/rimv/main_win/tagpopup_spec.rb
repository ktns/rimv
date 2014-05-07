require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*2, 'spec_helper.rb']))

describe Rimv::MainWin::TagPopup do
	before :each do
		@tagpopup = Rimv::MainWin::TagPopup.new double(:mainwin)
	end

	describe '#display' do
		context '(nil)' do
			it 'should raise TypeError' do
				lambda do
					@tagpopup.display nil
				end.should raise_error TypeError
			end
		end
	end
end
