require File.dirname(__FILE__) + '/spec_helper.rb'

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

describe Rimv::DB::TagTree::Node::Leaf do
	describe 'leaves with same hashes and different nodes' do
		before :all do
			@root_node = root_node
			@leaf1,@leaf2 = ['hoge','fuga'].collect do |s|
				Rimv::DB::TagTree::Node::Leaf.new('piyo',
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

describe Rimv::DB::TagTree do
	RSpec.configure do |config|
		config.before(:suite) do
			class Rimv::DB::TagTree
				attr_reader :root
			end
		end
	end

	describe 'complete tree' do
		before :all do
			unless self.class.class_variable_defined? :@@tree
				test_adaptor_open do |adaptor|
					raise 'tag tree was built multiple time!' if $complete_tag_tree_was_built
					$complete_tag_tree_was_built = true
					@@tree = Rimv::DB::TagTree.new(adaptor)
					@@tree.wait_until_loading
				end
			end
		end

		it 'should be consistent' do
			@@tree.should be_consistent
		end

		it 'should not be loading' do
			@@tree.should_not be_loading
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

		describe 'nodes' do
			it 'should all be enumerated by each_nodes' do
				enumerator = @@tree.nodes
				enumerator.all? do |n|
					n.should be_instance_of @@tree.class::Node
				end

				ObjectSpace.each_object(@@tree.class::Node).select do |n|
					n.tree.equal? @@tree
				end.each do |n|
					enumerator.should be_include n
				end
			end

			it 'should have consistent paths' do
				@@tree.each_nodes do |n|
					path = n.path
					path.first.should equal @@tree.root
					path.last.should equal n
					n.to_s.should =~ /\AROOT(->((?!->).)+)*\Z/
				end
			end

			it_should_behave_like 'nodes and leaves'
		end

		describe 'leaves' do
			it 'should exist' do
				@@tree.leaves.count.should > 0
			end

			it 'should all be Leaf class' do
				@@tree.each_leaves do |leaf|
					leaf.should be_kind_of(@@tree.class::Node::Leaf)
				end
			end

			it 'should have sane node' do
				@@tree.each_leaves do |leaf|
					leaf.node.should_not be_nil
					@@tree.nodes.should include leaf.node
				end
			end

			it 'next of last should return to first' do
				_first = @@tree.first
				_next = nil
				@@tree.leaves.count.times do
					_next = @@tree.next
				end
				_next.should_not be_nil
				_first.should equal _next
			end

			it 'should all be enuemrated by #next' do
				leaves = @@tree.leaves.entries
				lambda do
					leaves.delete @@tree.first
				end.should change(leaves, :size).by(-1)
				leaves.size.times do
					lambda do
						leaves.delete @@tree.next
					end.should change(leaves, :size).by(-1)
				end
				leaves.should be_empty
			end

			it_should_behave_like 'nodes and leaves'
		end

		describe 'current leaf' do
			it 'should be instance of Rimv::DB::TagTree::Node::Leaf'do
				@@tree.current.should be_instance_of Rimv::DB::TagTree::Node::Leaf
			end

			it 'should change after #next' do
				lambda do
					@@tree.next
				end.should change(@@tree,:current)
			end

			it 'should not change after next and prev' do
				@@tree.leaves.count.times do
					lambda do
						@@tree.next
						@@tree.prev
					end.should_not change(@@tree, :current)
					@@tree.next
				end
			end
		end

		describe 'isotopes' do
			shared_examples_for 'of any' do
				before :all do
					@orig = @@tree.send(enum).max_by{|item| item.path.count}
					@orig.path.size.should > 2
					@isotopes = @@tree.isotopes @orig
				end

				it 'should all be unique' do
					@isotopes.uniq.should == @isotopes
				end

				it 'should all have same tags if sorted' do
					@isotopes.each do |i|
						i.tags.sort.should == @orig.tags.sort
					end
				end

				it 'should all be same class as original' do
					@isotopes.each do |i|
						i.should be_instance_of(@orig.class)
					end
				end
			end

			describe 'of a node' do
				def enum
					:nodes
				end

				it_should_behave_like 'of any'
			end

			describe 'of a leaf' do
				def enum
					:leaves
				end

				it_should_behave_like 'of any'
			end
		end
	end

	describe 'node tagged with slash' do
		before :all do
			@root_node = root_node
			@root_node.add('hoge', ['a/b/c'])
		end

		it 'should have tag nodes splitted by slash' do
			@root_node.should_not       have_child 'a/b'
			@root_node.should           have_child 'a'
			@root_node['a'].should      have_child 'b'
			@root_node[*%w<a b>].should have_child 'c'
		end

		it 'should not have inverted relationship' do
			@root_node.should_not      have_child 'b'
			@root_node.should_not      have_child 'c'
			@root_node['a'].should_not have_child 'c'
		end

		describe 'and with duplicate parent tags' do
			before :all do
				@root_node.add('fuga', %w<c/d c/e>)
			end

			it 'should have a common parent node' do
				@root_node['c'].should have_child 'd'
				@root_node['c'].should have_child 'e'
			end

			it 'should not have parent tag in children again' do
				@root_node['c'].each_nodes do |child|
					child.should_not have_child 'c'
				end
			end

			it 'should return sane first leaf' do
				@root_node['c'].each_nodes do |node|
					node.first.to_s.should == 'fuga'
				end
			end

			it 'should not have duplicate path' do
				@root_node.each_nodes do |node|
					node.tags.uniq!.should be_nil
				end
			end
		end
	end
end
