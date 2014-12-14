#
# Copyright (C) Katsuhiko Nishimra 2011, 2012.
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

module ::Rimv
	# Class represents rectangular size.
	# Width and height are restricted to integer.
	class Size
		# Read only access to width value
		attr_reader :width
		# Read only access to height value
		attr_reader :height

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
