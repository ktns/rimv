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

module Rimv
	# Module that defines GDK keyval constants
	module Keyval
		include Gdk::Keyval

		# Module for GDK version workaround
		module ConstMissing
			def const_missing id
				if Gdk::Keyval.const_defined?(oid = id.to_s.sub('GDK_KEY_', 'GDK_'))
					const_set(id, const_get(oid))
				else
					super
				end
			end
		end

		# Extends successor for GDK version workaround
		def self.included klass
			klass.extend ConstMissing
		end
	end
end
