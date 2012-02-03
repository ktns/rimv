class Rimv::DB::TagTree
	class Leaf
		attr_reader :node

		def initialize hash, node
			raise TypeError, "String expected, but `#{hash.class}'" unless hash.instance_of?(String)
			raise TypeError, "Rimv::DB::TagTree::Node expected, but `#{node.class}'" unless node.instance_of?(Rimv::DB::TagTree::Node)
			@hash = hash
			@node = node
		end

		def to_s
			@hash
		end

		def === other
			@hash == other.to_s
		end

		def == other
			@hash == other.to_s and @node == other.node
		end

		def eql? other
			@hash.eql? other.to_s and @node.eql? other.node
		end

		def hash
			[@hash, @node].hash
		end

		def tree
			@node.tree
		end

		def inspect
			"#<#{self.class.name};#{@node.to_s}->#{to_s}>"
		end

		def path
			@node.path
		end

		def tags
			@node.tags
		end

		def next
			@node.next_hash_of self
		end

		def prev
			@node.prev_hash_of self
		end
	end
end
