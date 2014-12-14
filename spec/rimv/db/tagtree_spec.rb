#
# Copyright (C) Katsuhiko Nishimra 2011, 2012, 2014.
#
# This file is part of rimv.
#
# rimv is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Foobar is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*2, 'spec_helper.rb']))

class Rimv::DB::TagTree
	attr_reader :root
end

describe Rimv::DB::TagTree do
	describe 'complete tree' do
		before :all do
			unless @tree
				raise 'tag tree was built multiple time!' if $complete_tag_tree_was_built
				adaptor = MockAdaptor.new
				$complete_tag_tree_was_built = true
				@tree = Rimv::DB::TagTree.new(adaptor.hashtags)
				@tree.wait_until_loading
			end
		end

		it 'should be consistent' do
			expect(@tree).to be_consistent
		end

		it 'should not be loading' do
			expect(@tree).not_to be_loading
		end

		describe 'nodes' do
			it 'should all be enumerated by each_nodes' do
				enumerator = @tree.nodes
				enumerator.all? do |n|
					expect(n).to be_instance_of @tree.class::Node
				end

				ObjectSpace.each_object(@tree.class::Node).select do |n|
					n.tree.equal? @tree
				end.each do |n|
					expect(enumerator).to be_include n
				end
			end

			it 'should have consistent paths' do
				@tree.each_nodes do |n|
					path = n.path
					expect(path.first).to equal @tree.root
					expect(path.last).to equal n
					expect(n.to_s).to match(/\AROOT(->((?!->).)+)*\Z/)
				end
			end

			it_should_behave_like 'nodes and leaves'
		end

		describe 'leaves' do
			it 'should exist' do
				expect(@tree.leaves.count).to be > 0
			end

			it 'should all be Leaf class' do
				@tree.each_leaves do |leaf|
					expect(leaf).to be_kind_of(@tree.class::Leaf)
				end
			end

			it 'should have sane node' do
				@tree.each_leaves do |leaf|
					expect(leaf.node).not_to be_nil
					expect(@tree.nodes).to include leaf.node
				end
			end

			it 'next of last should return to first' do
				_first = @tree.first
				_next = nil
				@tree.leaves.count.times do
					_next = @tree.next
				end
				expect(_next).not_to be_nil
				expect(_first).to equal _next
			end

			it 'should all be enuemrated by #next' do
				leaves = @tree.leaves.entries
				expect do
					leaves.delete @tree.first
				end.to change(leaves, :size).by(-1)
				leaves.size.times do
					expect do
						leaves.delete @tree.next
					end.to change(leaves, :size).by(-1)
				end
				expect(leaves).to be_empty
			end

			it_should_behave_like 'nodes and leaves'
		end

		describe 'current leaf' do
			it 'should be instance of Rimv::DB::TagTree::Leaf'do
				expect(@tree.current).to be_instance_of Rimv::DB::TagTree::Leaf
			end

			it 'should change after #next' do
				expect do
					@tree.next
				end.to change(@tree,:current)
			end

			it 'should not change after next and prev' do
				@tree.leaves.count.times do
					expect do
						@tree.next
						@tree.prev
					end.not_to change(@tree, :current)
					@tree.next
				end
			end
		end

		describe 'isotopes' do
			shared_examples_for 'of any' do
				before :all do
					@orig = @tree.send(enum).max_by{|item| item.path.count}
					expect(@orig.path.size).to be > 2
					@isotopes = @tree.isotopes @orig
				end

				it 'should all be unique' do
					expect(@isotopes.uniq).to eq(@isotopes)
				end

				it 'should all have same tags if sorted' do
					@isotopes.each do |i|
						expect(i.tags.sort).to eq(@orig.tags.sort)
					end
				end

				it 'should all be same class as original' do
					@isotopes.each do |i|
						expect(i).to be_instance_of(@orig.class)
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
			expect(@root_node).not_to       have_child 'a/b'
			expect(@root_node).to           have_child 'a'
			expect(@root_node['a']).to      have_child 'b'
			expect(@root_node[*%w<a b>]).to have_child 'c'
		end

		it 'should not have inverted relationship' do
			expect(@root_node).not_to      have_child 'b'
			expect(@root_node).not_to      have_child 'c'
			expect(@root_node['a']).not_to have_child 'c'
		end

		describe 'and with duplicate parent tags' do
			before :all do
				@root_node.add('fuga', %w<c/d c/e>)
			end

			it 'should have a common parent node' do
				expect(@root_node['c']).to have_child 'd'
				expect(@root_node['c']).to have_child 'e'
			end

			it 'should not have parent tag in children again' do
				@root_node['c'].each_nodes do |child|
					expect(child).not_to have_child 'c'
				end
			end

			it 'should return sane first leaf' do
				@root_node['c'].each_nodes do |node|
					expect(node.first.to_s).to eq('fuga')
				end
			end

			it 'should not have duplicate path' do
				@root_node.each_nodes do |node|
					expect(node.tags.uniq!).to be_nil
				end
			end
		end
	end

	context 'with only one leaf' do
		shared_examples_for 'single leaf' do
			describe '#next' do
				it 'should return the identical leaf to first one' do
					expect(@first.next).to eq(@first)
				end
			end
		end

		context 'without tags' do
			before :all do
				@tree  = Rimv::DB::TagTree.new([['hoge',[]]])
				@first = @tree.first
			end

			it_should_behave_like 'single leaf'
		end

		context 'with a tag' do
			before :all do
				@tree  = Rimv::DB::TagTree.new([['hoge',['fuga']]])
				@first = @tree.first
			end

			it_should_behave_like 'single leaf'
		end
	end

	context 'with a leaf and with a node without a leaf' do
		before :all do
			@tree = Rimv::DB::TagTree.new([['hoge',['fuga']],['fuga',['piyo']]])
			until @tree.leaves.count > 0
				@tree.deq
			end
			@first = @tree.first
		end

		it 'should have a node witout a leaf' do
			expect(@tree.nodes).to be_any do |node|
				node.children.empty?
			end
		end

		it 'should have only one leaf' do
			expect(@tree.leaves.count).to eq(1)
		end

		describe 'existing leaf#next' do
			it 'should return existing leaf' do
				expect(@first.next).to eq(@first)
			end
		end

		describe 'existing leaf#prev' do
			it 'should return existing leaf' do
				expect(@first.prev).to eq(@first)
			end
		end
	end

	context 'with a leaf on root node and with a node without a leaf' do
		before :all do
			@tree = Rimv::DB::TagTree.new([['hoge',[]],['fuga',['fuga']]])
			while @tree.leaves.count < 2
				@tree.deq
			end
			@tree.root['fuga'].hashes.clear
			@first = @tree.first
		end

		it 'should have a node witout a leaf' do
			expect(@tree.nodes.select do |node|
				node.children.empty?
			end).to have_exactly(1).node
		end

		it 'should have only one leaf on the root node' do
			expect(@tree.leaves).to have_exactly(1).leaf
			expect(@tree.leaves.first.node).to eq(@tree.root)
		end

		describe 'existing leaf#next' do
			it 'should return existing leaf' do
				expect(@first.next).to eq(@first)
			end
		end

		describe 'existing leaf#prev' do
			it 'should return existing leaf' do
				expect(@first.prev).to eq(@first)
			end
		end
	end

	describe '#deq' do
		context 'called more times than hashes' do
			before :all do
				@tree = Rimv::DB::TagTree.new([['piyo',[]],['hoge',[]]])
			end

			it 'should not deadlock' do
				expect do
					3.times{@tree.deq}
				end.not_to raise_error
			end
		end
	end
end
