require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*1, 'spec_helper.rb'].flatten))

describe Rimv::DB do
	describe '.digest' do
		subject {Rimv::DB.digest(IO.read(File.join(asset_path,'logo.xpm')))}

		it 'should return String' do
			should be_kind_of String
		end
	end
end
