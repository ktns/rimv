require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*3, 'spec_helper.rb'].flatten))

describe Rimv::DB::TagTree::Node do
	before :each do
		@root_node = root_node
		@root_node.add('hoge', %w<a b>)
	end

	describe "['a', 'b'] and ['a']['b']" do
		it 'should be same' do
			@root_node[*%w<a b>].should equal @root_node['a']['b']
		end
	end
end
