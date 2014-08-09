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

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

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

shared_examples_for 'nodes and leaves' do
	describe '#tree' do
		it 'should return parent tree' do
			@tree.leaves.each do |leaf|
				leaf.should respond_to :tree
				leaf.tree.should equal @tree
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

	failure_message_for_should do |container|
		"expected #{container.inspect} to include only #{@type},\n" +
		"but found #{@rejected.first.inspect}"
	end
end

module Rimv
	if (verbosity=ENV['VERBOSITY'].to_i) > 0
		@@verbosity = verbosity
	end
end
