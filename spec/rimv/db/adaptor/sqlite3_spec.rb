#
# Copyright (C) Katsuhiko Nishimra 2011, 2012, 2014.
#
# This file is part of rimv.
#
# rimv is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Foobar is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*3, 'spec_helper.rb']))

describe Rimv::DB::Adaptor::SQLite3 do
	describe '.new' do
		it 'should be a private class method' do
			expect do
				Rimv::DB::Adaptor::SQLite3.new blank_db
			end.to raise_error(NoMethodError)
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
					expect(adaptor.addfile(logo_path)).to include \
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
		before :each do
			class Rimv::DB::Adaptor::SQLite3
				public_class_method :new
			end
			@adaptor = Rimv::DB::Adaptor::SQLite3.new(blank_db)
			@hash    = @adaptor.addfile logo_path
		end

		describe '#addtag' do
			it 'should add tag' do
				expect(@adaptor.hashtags.find{|hash,tags|hash==@hash}.last).to be_empty
				@adaptor.addtag @hash, 'tag'
				expect(@adaptor.hashtags.find{|hash,tags|hash==@hash}.last).to include 'tag'
			end
		end

		describe '#deltag' do
			before :each do
				@adaptor.addtag @hash, 'tag'
			end

			it 'should delete tag' do
				expect(@adaptor.hashtags.find{|hash,tags|hash==@hash}.last).to include 'tag'
				@adaptor.deltag @hash, 'tag'
				expect(@adaptor.hashtags.find{|hash,tags|hash==@hash}.last).to be_empty
			end
		end

		describe '#tags' do
			before :each do
				@tag = ("a".."z").to_a.sample(rand(1..8)).join
				@adaptor.addtag @hash, @tag
			end

			it 'should all be a String' do
				@adaptor.tags.each do |tag|
					expect(tag).to be_a String
				end
			end

			it 'should include added tag' do
				expect(@adaptor.tags).to include @tag
			end
		end

		describe '#transaction' do
			it 'should not raise error when nested' do
				expect{
					@adaptor.transaction do
						@adaptor.transaction do
							nil
						end
					end
				}.not_to raise_error
			end
		end

		after :each do
			@adaptor.close if @adaptor
		end
	end
end
