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
