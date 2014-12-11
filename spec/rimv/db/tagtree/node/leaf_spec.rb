require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*4, 'spec_helper.rb']))

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
			expect(hash1).to eq(hash2)
			expect(hash1).to be === hash2
		end

		it 'should have different node' do
			expect(@leaf1.node).not_to equal @leaf2.node
			expect(@leaf1.node).not_to eql @leaf2.node
			expect(@leaf1.node).not_to eq(@leaf2.node)
			expect(@leaf1.node).not_to be === @leaf2.node
		end

		it 'should not be equal' do
			expect(@leaf1).not_to equal @leaf2
			expect(@leaf1).not_to eql @leaf2
			expect(@leaf1).not_to eq(@leaf2)
		end

		it 'should be equal with ===' do
			expect(@leaf1).to be === @leaf2
		end
	end
end
