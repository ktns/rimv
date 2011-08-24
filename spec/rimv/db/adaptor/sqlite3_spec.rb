require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*3, 'spec_helper.rb'].flatten))

describe Rimv::DB::Adaptor::SQLite3 do
	describe 'with blank database' do
		it 'should be able to add an image' do
			Rimv::DB::Adaptor::SQLite3.open(blank_db) do |adaptor|
				adaptor.addfile(File.join(asset_path, 'logo.xpm'))
			end
		end
	end
end
