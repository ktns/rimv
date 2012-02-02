module ::Rimv
	# Class represents rectangular size.
	# Width and height are restricted to integer.
	class Size
		# R/W access to width value
		attr_accessor :width
		# R/W access to height value
		attr_accessor :height

		# Creates a new instance with given width and height.
		# Width and height are converted to Integer by to_i method.
		def initialize width, height
			@width, @height = [width, height].collect &:to_i
		end

		# Creates a new instance from various sources.
		# Accepts a pair of width and heght, or any instance responds to method size.
		def self.[] *arg
			case arg.size
			when 1
				arg = arg.first
				if arg.kind_of?(Array)
					self.new(*arg)
				elsif arg.respond_to?(:size)
					self.new(*arg.size)
				else
					self.new(arg.width, arg.height)
				end
			when 2
				self.new(*arg)
			else
				raise ArgumentError, "#{arg.size} arguments is not supported!"
			end
		end

		# Returns an array containing the width and the height
		def to_a
			[@width, @height]
		end

		# Returns a string in format "[width,height]"
		def to_s
			"[#{@width},#{@height}]"
		end

		# Compares self with the rhs.
		# Returns true only if the rhs is an intance of Size.
		def == other
			other.kind_of?(self.class) and
			to_a == other.to_a
		end

		# Operates the same operation on both width and height
		def op_for_both other, &block
			case other
			when Size
				Size.new(*([[@width, other.width],
									 [@height, other.height]].collect &block))
			when Array
				op_for_both Size.new(*other)
			else
				raise TypeError, "Invalid class `#{other.class}'!"
			end
		end
		private :op_for_both

		# Adds the operand to self.
		def + other
			op_for_both(other){|s,o| s + o}
		end

		# Subtracts the operand from self.
		def - other
			op_for_both(other){|s,o| s - o}
		end

		# Multiplys self by the operand.
		def * other
			Size.new(@width * other, @height * other)
		end

		# Devides self by the operand.
		def / other
			Size.new(@width / other, @height / other)
		end

		# Returns a Size with the absolute value of the width and height 
		def abs
			Size.new(@width.abs, @height.abs)
		end

		# Returns a Size scaled to fit the specified frame.
		def fit frame
			ratio = [frame.width.to_f/@width,frame.height.to_f/@height].min
			Size[@width * ratio, @height *ratio]
		end
	end
end
