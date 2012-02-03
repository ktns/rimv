require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*4, 'spec_helper.rb'].flatten))

describe Rimv::DB::TagTree::Leaf do
	describe 'leaves with same hashes and different nodes' do
		before :all do
			@root_node = root_node
			@leaf1,@leaf2 = ['hoge','fuga'].collect do |s|
				Rimv::DB::TagTree::Leaf.new('piyo',
																					Rimv::DB::TagTree::Node.new(@root_node, s)
																				 )
			end
		end

		it 'should have equal hash' do
			hash1, hash2 = @leaf1.to_s, @leaf2.to_s
			hash1.should == hash2
			hash1.should === hash2
		end

		it 'should have different node' do
			@leaf1.node.should_not equal @leaf2.node
			@leaf1.node.should_not eql @leaf2.node
			@leaf1.node.should_not == @leaf2.node
			@leaf1.node.should_not === @leaf2.node
		end

		it 'should not be equal' do
			@leaf1.should_not equal @leaf2
			@leaf1.should_not eql @leaf2
			@leaf1.should_not == @leaf2
		end

		it 'should be equal with ===' do
			@leaf1.should === @leaf2
		end
	end
end
