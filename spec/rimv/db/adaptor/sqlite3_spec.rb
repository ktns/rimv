require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*3, 'spec_helper.rb'].flatten))

describe Rimv::DB::Adaptor::SQLite3 do
	describe '.new' do
		it 'should be a private class method' do
			lambda do
				Rimv::DB::Adaptor::SQLite3.new blank_db
			end.should raise_error(NoMethodError)
		end
	end

	describe 'with blank database' do
		it 'should be able to add an image' do
			Rimv::DB::Adaptor::SQLite3.open(blank_db) do |adaptor|
				adaptor.addfile(logo_path)
			end
		end

		describe '#addfile' do
			it 'should return file hash' do
				Rimv::DB::Adaptor::SQLite3.open(blank_db) do |adaptor|
					adaptor.addfile(logo_path).should include \
						Rimv::DB.digest IO.read(logo_path)
				end
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

	describe 'with a image' do
		before :all do
			class Rimv::DB::Adaptor::SQLite3
				public_class_method :new
			end
			@adaptor = Rimv::DB::Adaptor::SQLite3.new(blank_db)
			@hash    = @adaptor.addfile logo_path
		end

		describe '#addtag' do
			it 'should add tag' do
				@adaptor.hashtags.find{|hash,tags|hash==@hash}.last.should be_empty
				@adaptor.addtag @hash, 'tag'
				@adaptor.hashtags.find{|hash,tags|hash==@hash}.last.should include 'tag'
			end
		end

		after :all do
			@adaptor.close if @adaptor
		end
	end
end
