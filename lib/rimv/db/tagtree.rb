module Rimv::DB
	class TagTree
		include Rimv

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
			node, hash, tags = *@queue.deq
			verbose(3).puts {'Dequeuing TagTree node: node=%s, hash=%s, tags=%s' % [node,hash,tags].collect(&:inspect)}
			node ||= @root
			node.add hash, tags
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

		def prev
			@current = @current.prev
		end

		def last
			@root.last
		end

		def random
			@random_hist.push @current
			@current = leaves.entries[rand(leaves.count)]
		end

		def random_prev
			@current = @random_hist.pop or random
		end

		def each_leaves &block
			@root.each_leaves &block
		end

		def leaves
			@root.leaves
		end

		def each_nodes &block
			@root.each_nodes &block
		end

		def nodes
			@root.nodes
		end

		def isotopes item
			node = item.instance_of?(Node::Leaf) ? item.node : item
			raise ArgumentError, "#{Node} expected, but #{node.class}" unless
			node.instance_of?(Node)
			isotopes = @root.shuffle item.path.collect{|node| node.tag}.compact
			case item
			when Node
				isotopes
			when Node::Leaf
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
