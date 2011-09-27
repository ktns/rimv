require 'rimv/db/adaptor.rb'

module Rimv
	module DB
		@@adaptor=Adaptor::SQLite3

		def self.open db_file=nil, &block
			@@adaptor.open db_file, &block
		end

		def self.digest img
			Digest::MD5.digest(img).unpack('h*').first
		end

		def self.acceptable_tag? tag
			/\A\w+(\/\w+)*\Z/ =~ tag
		end
	end
end

require 'rimv/db/tagtree'
