require 'rimv/db/adaptor.rb'

module Rimv
	#Namespace for database related functions
	module DB
		@@adaptor=Adaptor::SQLite3

		# Open database with the default database adaptor
		def self.open db_file=nil, &block
			@@adaptor.open db_file, &block
		end

		# generate MD5 digest of an image for an access key
		def self.digest img
			Digest::MD5.digest(img).unpack('h*').first
		end

		# Character set available in a tag string
		TAG_CHARS='[\w.+\-_]'

		# Check if the string is accectable as a tag
		def self.acceptable_tag? tag
			/\A#{TAG_CHARS}+(\/#{TAG_CHARS}+)*\Z/ =~ tag
		end
	end
end

require 'rimv/db/tagtree'
