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

def asset_path
	asset_path = File.expand_path(File.join(File.dirname(__FILE__), *%w<.. asset>))
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
