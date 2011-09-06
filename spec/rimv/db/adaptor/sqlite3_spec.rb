require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*3, 'spec_helper.rb'].flatten))

describe Rimv::DB::Adaptor::SQLite3 do
	def logo_path
		File.join(asset_path, 'logo.xpm')
	end
	describe 'with blank database' do
		it 'should be able to add an image' do
			Rimv::DB::Adaptor::SQLite3.open(blank_db) do |adaptor|
				adaptor.addfile(logo_path)
			end
		end
	end

	describe 'with some tags' do
		before :all do
			class Rimv::DB::Adaptor::SQLite3
				public_class_method :new
			end
			@adaptor = Rimv::DB::Adaptor::SQLite3.new(blank_db)
			@adaptor.addtag 'hoge', 'piyo'
		end

		subject {@adaptor}

		its(:tags) { should include_only String }

		after :all do
			@adaptor.close
		end
	end
end
