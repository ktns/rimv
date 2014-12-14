#
# Copyright (C) Katsuhiko Nishimra 2010, 2011, 2012.
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

module Rimv::DB
	# Construct tag tree structure for browsing
	class TagTree
		include Rimv

		# Currently selected Leaf node
		attr_reader :current

		#Initialize TagTree from tuples of hash and tags
		def initialize hashtags
			verbose(2).puts 'Initializing TagTree...'
			@queue       = Queue.new
			@root        = Node.new(self, nil)
			@random_hist = []
			@thread = Thread.new do
				Thread.current.abort_on_exception = true
				hashtags.each do |hash, tags|
					enq nil, hash, tags
				end
			end
			verbose(3).puts 'Waiting for first leaf to be added...'
			until leaves.count > 0
				deq
			end
			@current = first
			verbose(3).puts 'First leaf has now been added.'
			GLib::Idle.add{deq}
		end

		#Enqueue a tuple of hash and tags into @queue
		def enq node, hash, tags
			verbose(3).puts {'Enqueuing TagTree node: node=%s, hash=%s, tags=%s' % [node,hash,tags].collect(&:inspect)}
			@queue.enq [node, hash, tags]
		end

		#Dequeue a tuple of hash and tags from @queue,
		#and build corresponding nodes and leaves
		def deq
			unless @queue.empty?
				node, hash, tags = *@queue.deq
				verbose(3).puts {'Dequeuing TagTree node: node=%s, hash=%s, tags=%s' % [node,hash,tags].collect(&:inspect)}
				node ||= @root
				node.add hash, tags
			end
		end

		#Returns true if TagTree has not finished loading
		def loading?
			@thread.alive? or not @queue.empty?
		end

		#Ensure TagTree has finished loading
		def wait_until_loading
			@thread.join
			until @queue.empty?
				deq
			end
		end

		#Check consistency of TagTree
		def consistent?
			@root.consistent?
		end

		#Return and set @current to first leaf
		def first
			@current = @root.first
		end

		#Return and set @current to next leaf of @current
		def next
			@current = @current.next
		end

		# Returns the previous leaf of the current leaf
		def prev
			@current = @current.prev
		end

		# Returns the last leaf of the tree
		def last
			@root.last
		end

		# Returns a random leaf and add the current leaf to the history
		def random
			@random_hist.push @current
			@current = leaves.entries[rand(leaves.count)]
		end

		# Pops and returns a leaf pushed into history previously by #random
		def random_prev
			@current = @random_hist.pop or random
		end

		# Enumerates leaves and yield a given block
		def each_leaves &block
			@root.each_leaves &block
		end

		# Returns an Array containing all the leaves
		def leaves
			@root.leaves
		end

		# Enumerates nodes and yield a given block
		def each_nodes &block
			@root.each_nodes &block
		end

		# Returns an Array containing all the leaves
		def nodes
			@root.nodes
		end

		# Returns Nodes/Leafs with shuffled path
		def isotopes item
			node = item.instance_of?(Leaf) ? item.node : item
			raise ArgumentError, "#{Node} expected, but #{node.class}" unless
			node.instance_of?(Node)
			isotopes = @root.shuffle item.path.collect{|node| node.tag}.compact
			case item
			when Node
				isotopes
			when Leaf
				isotopes.collect do |i|
					i.hashes.find{|h| h.to_s == item.to_s}
				end
			else
				raise
			end
		end
	end
end

require 'rimv/db/tagtree/node'
