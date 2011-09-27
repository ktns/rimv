module Rimv
	module Keyval
		include Gdk::Keyval

		def self.const_missing id
			if constants.include?(oid = id.to_s.sub('GDK_KEY_', 'GDK_'))
				const_set(id, const_get(oid))
			else
				super
			end
		end
	end
end
