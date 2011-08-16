module ::Rimv
	class Size
		attr_accessor :width, :height

		def initialize width, height
			@width, @height = [width, height].collect &:to_i
		end

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
				self.new(arg.first,arg.last)
			else
				raise ArgumentError, "#{arg.size} arguments is not supported!"
			end
		end

		def to_a
			[@width, @height]
		end

		def to_s
			"[#{@width},#{@height}]"
		end

		def == other
			other.kind_of?(self.class) and
			@width == other.width && @height == other.height
		end

		def op_for_both other, &block
			case other
			when Size
				Size.new(*([[@width, other.width],
									 [@height, other.height]].collect &block))
			when Array
				self - Size.new(*other)
			else
				raise TypeError, "Invalid class `#{other.class}'!"
			end
		end
		private :op_for_both

		def + other
			op_for_both(other){|s,o| s + o}
		end

		def - other
			op_for_both(other){|s,o| s - o}
		end

		def * other
			Size.new(@width * other, @height * other)
		end

		def / other
			Size.new(@width / other, @height / other)
		end

		def abs
			Size.new(@width.abs, @height.abs)
		end

		def fit frame
			ratio = [frame.width.to_f/@width,frame.height.to_f/@height].min
			Size[@width * ratio, @height *ratio]
		end
	end
end
