#
# Copyright (C) Katsuhiko Nishimra 2010, 2011, 2012, 2014.
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

require 'simplecov'
SimpleCov.start do
	add_filter "/spec/"
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rspec/collection_matchers'
require 'rspec/its'
require 'rimv'
require 'rimv/cli'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

Rimv::App = Rimv::Application.new

class TreeStub < Rimv::DB::TagTree
	def initialize
		@queue=Queue.new
	end

	def instance_of? klass
		if klass == Rimv::DB::TagTree
			true
		else
			super
		end
	end

	def enq node, hash, tags
		@queue.enq [node,hash,tags]
		deq
	end
end

def tree_stub
	TreeStub.new
end

def root_node
	Rimv::DB::TagTree::Node.new(tree_stub, nil)
end

def test_adaptor_open &block
	Rimv::DB::Adaptor::SQLite3.open("#{ENV['HOME']}/.imv.sqlite3.test", &block)
end

def blank_db
	require 'tmpdir'
	tmpdir=Dir.mktmpdir
	at_exit do
		require 'fileutils'
		FileUtils.rm_rf tmpdir
	end
	File.join(tmpdir,'db')
end

def fixtures_path
	File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))
end

require 'yaml'
class MockAdaptor < Rimv::DB::Adaptor

	def initialize hashtags=nil
		@hashtags = hashtags
	end

	def each_hash_tags &block
		if @hashtags
			@hashtags.each &block
		else
			File.open(File.join(fixtures_path, 'hashtags.yml'),'r') do |f|
				YAML.load(f).each &block
			end
		end
	end

	def tags
		hashtags.collect(&:last).flatten.uniq
	end

	# Add an image to the database (no implementation)
	def addimage name, img
	end

	# Add a tag to an image specified by hash(no implementation)
	def addtag hash, tag
	end

	# Delete a tag from an image specified by hash(no implementation)
	def deltag hash, tag
	end

	# Read image binary data from db (no implementation)
	def getimage_bin hash
	end
end

def asset_path *args
	File.expand_path(File.join(File.dirname(__FILE__), %w<.. asset>, *args))
end

def logo_path
	asset_path 'logo.png'
end

def read_logo
	IO.read(logo_path)
end

TAG_CHARS=("\x00".."\x7f").grep(/#{Rimv::DB::TAG_CHARS}/)
def random_tag
	TAG_CHARS.sample(rand(1..8)).join
end

shared_examples_for 'nodes and leaves' do
	describe '#tree' do
		it 'should return parent tree' do
			@tree.leaves.each do |leaf|
				expect(leaf).to respond_to :tree
				expect(leaf.tree).to equal @tree
			end
		end
	end
end

require 'rspec/expectations'

RSpec::Matchers.define :include_only do |type|
	match do |container|
		@type = type
		@rejected = container.reject do |e|
			type === e
		end
		@rejected.empty?
	end

	failure_message do |container|
		"expected #{container.inspect} to include only #{@type},\n" +
		"but found #{@rejected.first.inspect}"
	end
end
