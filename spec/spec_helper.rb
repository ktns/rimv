begin
  require 'rspec'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rspec'
  require 'rspec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'rimv'

class TreeStub
	def instance_of? klass
		if klass == Rimv::DB::TagTree
			true
		else
			super
		end
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
class MockAdaptor
	include Rimv::DB::Adaptor

	def each_hash_tags &block
		File.open(File.join(fixtures_path, 'hashtags.yml'),'r') do |f|
			YAML.load(f).each &block
		end
	end

	def tags
		hashtags.collect(&:last).flatten.uniq
	end
end

def asset_path
	File.expand_path(File.join(File.dirname(__FILE__), *%w<.. asset>))
end

shared_examples_for 'nodes and leaves' do
	describe '#tree' do
		it 'should return parent tree' do
			@@tree.leaves.each do |leaf|
				leaf.should respond_to :tree
				leaf.tree.should equal @@tree
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
