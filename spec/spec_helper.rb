begin
  require 'spec'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'rimv'

def tree_stub
	tree_stub = stub(:tagtree)
	tree_stub.stub!(:instance_of?).with(Rimv::DB::TagTree).and_return(true)
	tree_stub.stub!(:instance_of?).with(Rimv::DB::TagTree::Node).and_return(false)
	tree_stub
end

def root_node
	Rimv::DB::TagTree::Node.new(tree_stub, nil)
end
