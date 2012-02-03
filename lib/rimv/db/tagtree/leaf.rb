class Rimv::DB::TagTree
	# Leaf node of the bi-directional TagTree structure
	class Leaf
		# Parent Node
		attr_reader :node

		# Creates a new Leaf node under the specified Node with the specified hash
		def initialize hash, node
			raise TypeError, "String expected, but `#{hash.class}'" unless hash.instance_of?(String)
			raise TypeError, "Rimv::DB::TagTree::Node expected, but `#{node.class}'" unless node.instance_of?(Rimv::DB::TagTree::Node)
			@hash = hash
			@node = node
		end

		# Returns hash
		def to_s
			@hash
		end

		# Returns true if operand.to_s matches the hash
		def === other
			@hash == other.to_s
		end

		# Returns true if operand is the same Leaf node
		def == other
			@hash == other.to_s and @node == other.node
		end

		# Returns true if operand is the same Leaf node
		def eql? other
			@hash.eql? other.to_s and @node.eql? other.node
		end

		# Returns object hash
		def hash
			[@hash, @node].hash
		end

		# Returns the TagTree object that contains the Leaf node
		def tree
			@node.tree
		end

		# Returns a string to distinguish the object
		def inspect
			"#<#{self.class.name};#{@node.to_s}->#{to_s}>"
		end

		# Returns the path of the parent Node
		def path
			@node.path
		end

		# Returns the tag string of the parent Node
		def tags
			@node.tags
		end

		# Returns the next Leaf node
		def next
			@node.next_hash_of self
		end

		# Returns the previous Leaf node
		def prev
			@node.prev_hash_of self
		end
	end
end
