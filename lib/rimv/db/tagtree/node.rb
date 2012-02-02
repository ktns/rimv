class Rimv::DB::TagTree
	# Node of the bi-directional TagTree structure
	class Node
		include Rimv
		# Parent node
		attr_reader :parent
		# Tag string of the node
		attr_reader :tag
		# Child nodes (not leaf) of the node
		attr_reader :children
		# Child leaf nodes of the node
		attr_reader :hashes

		# Compares nodes by tag strings
		def <=> other
			raise TypeError unless other.kind_of?(self.class)
			raise ArgumentError,
				'Comparing TagTree::Nodes having different parent!' unless @parent == other.parent
			raise 'Comparing root nodes does not make sense!' unless @parent
			tag <=> other.tag
		end

		# Returns the TagTree object that contains the node
		def tree
			if @parent.instance_of?(Rimv::DB::TagTree)
				@parent
			else
				@parent.tree
			end
		end

		# Array of nodes between the root and self
		def path
			path = []
			node = self
			until node.instance_of?(Rimv::DB::TagTree)
				path.unshift node
				node = node.parent
			end
			return path
		end

		# Array of tag strings tagged the nodes between the root and self
		def tags
			path.collect{|n| n.tag}.compact
		end

		# Returns a string to distinguish the node
		def to_s
			path.collect do |node|
				if node.parent.instance_of?(Rimv::DB::TagTree)
					'ROOT'
				else
					node.tag
				end
			end.join('->')
		end

		# Returns a string to distinguish the object
		def inspect
			"#<#{self.class.name};#{to_s}>"
		end

		# Creates a child node of the specified parent with the specified tag
		def initialize parent, tag
			verbose(4).puts do
				'Initializing new TagTree Node; ' +
				"parent=#{parent ? parent.to_s : 'none'}, tag = #{tag}"
			end
			unless [self.class, Rimv::DB::TagTree].any?{|c| parent.instance_of?(c)}
				raise TypeError, "`#{self.class}' or `#{Rimv::DB::TagTree}' expected, but `#{parent.class}'"
			end
			unless tag.nil? || tag.instance_of?(String)
				raise TypeError, "`#{String}' or nil expected, but `#{tag.class}'"
			end
			@parent, @tag = parent, tag
			@children     = []
			@hashes       = []
		end

		# Checks consistency as a node of TagTree
		def consistent? depth = 0
			verbose(1).puts {"Consistency Check for tag #{@tag}, depth #{depth}"}
			@children.each do |c|
				unless c.parent == self
					raise "TagTree consistency Error! tag = #{@tag}, depth = #{depth}"
					return false
				end
				raise unless c.consistent?(depth+1) == true
			end
			true
		end

		# Adds Leaf nodes with tags under the node recursively and creates its parent Nodes if not exist.
		# Creates Leaf nodes with all possible path order.
		# Tag strings with '/' are splitted, but not their order is conserved.
		def add hash, tags
			raise TypeError.new('Expected Enumerable but %s for tags!' % tags.class) unless tags.kind_of?(Enumerable)
			verbose(4).puts do
				"adding hash `#{hash}' onto #{self}; " +
				"tagstack [#{tags.join(', ')}]"
			end
			if tags.empty?
				new_leaf = Leaf.new(hash, self)
				@hashes.push new_leaf unless @hashes.include? new_leaf
			else
				tags.each do |tag_with_slash|
					tags_splitted = tag_with_slash.split('/')
					begin
						tag = tags_splitted.shift
					end while self.tags.include? tag && tag
					next unless tag
					unless child = self[tag]
						@children.push(child = self.class.new(self, tag))
						@children.sort!
					end
					raise "#{self.class} expected, but #{child.class}!" unless child.class == self.class
					tree.enq(child, hash, [tags, tags_splitted.join('/')].flatten.reject(&:empty?) - [tag_with_slash, child.tags].flatten)
				end
			end
		end

		# Returns the first Leaf node under self or under the next Node
		def first
			raise ScriptError, "#{self.inspect}#\@hashes was nil!" if @hashes.nil?
			raise ScriptError, "#{self.inspect}#\@children was nil!" if @children.nil?
			#raise ScriptError, "#{self.inspect}#\@hashes and @children were both empty" if @hashes.empty? && @children.empty?
			return @parent.next_node_of(self).first if @hashes.empty? && @children.empty?
			@hashes.first or
			@children.first.first or
			raise "#{inspect}.first returned nil"
		end

		# Returns the next Leaf node of the specified Leaf node
		def next_hash_of hash
			@hashes[@hashes.index(hash)+1] or
			if @children.empty?
				if @parent.instance_of?(self.class)
					@parent.next_node_of(self).first
				else
					first
				end
			else
				@children.first.first
			end
		end

		# Returns the next Node of the specified Node
		def next_node_of node
			@children[@children.index(node)+1] or
			unless @parent.instance_of?(Rimv::DB::TagTree)
				@parent.next_node_of(self)
			else
				self
			end
		end

		# Returns the last child Leaf node
		def last_hash
			@hashes.last
		end

		# Returns the last child Node, if exists, or self
		def last_node
			if @children.empty?
				self
			else
				@children.last.last_node
			end
		end

		# Returns the previous Leaf Node of the specified Leaf node
		def prev_hash_of hash
			if (index = @hashes.index(hash)-1) >= 0
				@hashes[index]
			else
				node = self
				begin
					if node.parent.instance_of?(Rimv::DB::TagTree)
						return last_node.last_hash
					end
					node = node.parent.prev_node_of(node)
				end until node.last_hash
				node.last_hash
			end
		end

		# Returns the previous Node of the specified Node
		def prev_node_of node
			if ( index = @children.index(node)-1 ) >= 0
				@children[index].last_node
			else
				self
			end
		end

		# Enumerates all Leaf nodes under self
		def each_leaves &block
			raise ArgumentError, 'each_leaves called without block!' unless block.kind_of?(Proc)
			@hashes.each &block
			@children.each do |c|
				c.each_leaves &block
			end
		end

		# Returns enumerator with each_leaves
		def leaves
			Enumerator.new(self, :each_leaves)
		end

		# Enumerates all Nodes under self including self
		def each_nodes &block
			raise ArgumentError, 'each_nodes called without block!' unless block.kind_of?(Proc)
			yield self
			@children.each do |c|
				c.each_nodes &block
			end
		end

		# Returns enumerator with each_nodes
		def nodes
			Enumerator.new(self, :each_nodes)
		end

		# Returns Nodes which have tags shuffled into all possible order as path
		def shuffle tags
			if tags.empty?
				self
			else
				tags.collect do |tag|
					next unless self.has_child? tag
					self[tag].shuffle tags - [tag]
				end.compact.flatten
			end
		end

		# Returns the child Node with specified tag
		def [] tag, *tags
			unless tags.empty?
				self[tag][*tags]
			else
				@children.find do |child|
					child.tag == tag
				end
			end
		end

		# Tells whether the Node have any child Node
		def has_child? tag
			@children.any? do |child|
				child.tag == tag
			end
		end
	end
end

require 'rimv/db/tagtree/node/leaf'
