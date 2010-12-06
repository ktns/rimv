module Rimv::DB
	class TagTree
		include Rimv

		def sync
			@mutex.lock
			begin
				return yield
			ensure
				@mutex.unlock
			end
		end

		attr_reader :current

		def initialize db
			verbose(2).puts 'Initializing TagTree...'
			raise unless db.kind_of?(Rimv::DB)
			@mutex       = Mutex.new
			@root        = Node.new(self, nil)
			@random_hist = []
			@thread = Thread.new do
				Thread.current.abort_on_exception = true
				db.each_hash_tags do |hash, tags|
					sync do
						@root.add hash, tags
					end
				end
			end
			verbose(3).puts 'Waiting for first leaf to be added...'
			Thread.pass until sync {leaves.count > 0}
			@current = first
			verbose(3).puts 'First leaf has now been added.'
		end

		def loading?
			@thread.alive?
		end

		def wait_until_loading
			@thread.join
		end

		def consistent?
			sync do
				@root.consistent?
			end
		end

		def first
			sync do
				@current = @root.first
			end
		end

		def next
			sync do
				@current = @current.next
			end
		end

		def prev
			sync do
				@current = @current.prev
			end
		end

		def last
			sync do
				@root.last
			end
		end

		def random
			sync do
				@random_hist.push @current
				@current = leaves.entries[rand(leaves.count)]
			end
		end

		def random_prev
			sync do
				@current = @random_hist.pop
			end || random
		end

		def each_leaves &block
			sync do
				@root.each_leaves &block
			end
		end

		def leaves
			@root.leaves
		end

		def each_nodes &block
			sync do
				@root.each_nodes &block
			end
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
