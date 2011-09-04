module Rimv
	module Keyval
		include Gdk::Keyval

		module ConstMissing
			def const_missing id
				if constants.include?(oid = id.to_s.sub('GDK_KEY_', 'GDK_'))
					const_set(id, const_get(oid))
				else
					super
				end
			end
		end

		def self.included klass
			klass.extend ConstMissing
		end
	end
end
