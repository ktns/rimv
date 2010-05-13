begin
  require 'spec'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'rimv'

def tree_mock
	tree_mock = mock(:tagtree)
	tree_mock.stub!(:instance_of?).with(Rimv::DB::TagTree).and_return(true)
	tree_mock.stub!(:instance_of?).with(Rimv::DB::TagTree::Node).and_return(true)
	tree_mock
end
