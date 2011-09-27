module Rimv::DB
	class TagTree
		include Rimv

		attr_reader :current

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

		def enq node, hash, tags
			verbose(3).puts {'Enqueuing TagTree node: node=%s, hash=%s, tags=%s' % [node,hash,tags].collect(&:inspect)}
			@queue.enq [node, hash, tags]
		end

		def deq
			node, hash, tags = *@queue.deq
			verbose(3).puts {'Dequeuing TagTree node: node=%s, hash=%s, tags=%s' % [node,hash,tags].collect(&:inspect)}
			node ||= @root
			node.add hash, tags
		end

		def loading?
			@thread.alive?
		end

		def wait_until_loading
			@thread.join
			until @queue.empty?
				deq
			end
		end

		def consistent?
			@root.consistent?
		end

		def first
			@current = @root.first
		end

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
