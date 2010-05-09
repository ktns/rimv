class Rimv::DB::TagTree
	class Node
		include Rimv
		attr_reader :parent, :tag, :children, :hashes

		def <=> other
			raise TypeError unless other.kind_of?(self.class)
			raise ArgumentError,
				'Comparing TagTree::Nodes having different parent!' unless @parent == other.parent
			raise 'Comparing root nodes does not make sense!' unless @parent
			tag <=> other.tag
		end

		def path
			path = []
			node = self
			while node
				path.unshift node
				node = node.parent
			end
			return path
		end

		def tags
			path.collect{|n| n.tag}.compact
		end

		def to_s
			path.collect{|node| node.tag or 'ROOT'}.join('->')
		end

		def inspect
			"#<#{self.class.name};#{to_s}>"
		end

		def initialize parent, tag
			verbose(4).puts 'Initializing new TagTree Node; ' +
				"parent=#{parent ? parent.to_s : 'none'}, tag = #{tag}"
			[
				[parent,self.class],
				[tag,String]
			].each do |v,c|
				unless v == nil || v.kind_of?(c)
					raise TypeError "`#{c}' expected, but `#{v.class}'"
				end
			end
			@parent, @tag = parent, tag
			@children     = []
			@hashes       = []
		end

		def consistent? depth = 0
			verbose(1).puts "Consistency Check for tag #{@tag}, depth #{depth}"
			@children.each do |c|
				unless c.parent == self
					raise "TagTree consistency Error! tag = #{@tag}, depth = #{depth}"
					return false
				end
				raise unless c.consistent?(depth+1) == true
			end
			true
		end

		def add hash, tags
			verbose(4).puts "adding hash `#{hash}' into TagTree; " +
				"tagstack [#{tags.join(', ')}]"
			if tags.empty?
				new_leaf = Leaf.new(hash, self)
				raise "Duplicate leaf #{new_leaf} added to #{self}" if @hashes.include? new_leaf
				@hashes.push new_leaf
			else
				tags.each do |tag|
					unless child = @children.find{|c|c.tag == tag}
						@children.push(child = self.class.new(self, tag))
						@children.sort!
					end
					raise "#{self.class} expected, but #{child.class}!" unless child.class == self.class
					child.add(hash, tags.reject{|t| t == tag})
				end
			end
		end

		def first
			@hashes.first or @children.first.first or
			raise "#{inspect}.first returned nil"
		end

		def next_hash_of hash
			@hashes[@hashes.index(hash)+1] or
			if @children.empty?
				@parent.next_node_of(self).first
			else
				@children.first.first
			end
		end

		def next_node_of node
			@children[@children.index(node)+1] or
			if @parent
				@parent.next_node_of(self)
			else
				self
			end
		end

		def last_hash
			@hashes.last
		end

		def last_node
			if @children.empty?
				self
			else
				@children.last.last_node
			end
		end

		def prev_hash_of hash
			if (index = @hashes.index(hash)-1) >= 0
				@hashes[index]
			else
				if @parent
					node = self
					begin
						node = node.parent.prev_node_of(node)
					end until node.last_hash
					node.last_hash
				else
					last_node.last_hash
				end
			end
		end

		def prev_node_of node
			if ( index = @children.index(node)-1 ) >= 0
				@children[index].last_node
			else
				self
			end
		end

		def each_leaves &block
			raise ArgumentError, 'each_leaves called without block!' unless block.kind_of?(Proc)
			@hashes.each &block
			@children.each do |c|
				c.each_leaves &block
			end
		end

		def leaves
			Enumerable::Enumerator.new(self, :each_leaves)
		end

		def each_nodes &block
			raise ArgumentError, 'each_nodes called without block!' unless block.kind_of?(Proc)
			yield self
			@children.each do |c|
				c.each_nodes &block
			end
		end

		def nodes
			Enumerable::Enumerator.new(self, :each_nodes)
		end

		def shuffle tags
			if tags.empty?
				self
			else
				tags.collect do |tag|
					@children.find{|c| c.tag == tag}.shuffle tags - [tag]
				end.flatten
			end
		end
	end
end

require 'rimv/db/tagtree/node/leaf'
