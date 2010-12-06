begin
  require 'rspec'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rspec'
  require 'rspec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'rimv'

def tree_stub
	tree_stub = stub(:tagtree)
	class <<tree_stub
		def instance_of? klass
			if klass == Rimv::DB::TagTree
				true
			else
				super
			end
		end
	end
	tree_stub
end

def root_node
	Rimv::DB::TagTree::Node.new(tree_stub, nil)
end
