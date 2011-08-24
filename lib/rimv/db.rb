require 'rimv/db/adaptor.rb'

module Rimv
	module DB
		@@adaptor=Adaptor::SQLite3

		def self.open db_file=nil, &block
			@@adaptor.open db_file, &block
		end
	end
end

require 'rimv/db/tagtree'
