require 'rimv/db/adaptor.rb'

module Rimv
	module DB
		@@adaptor=Adaptor::SQLite3
	end
end

require 'rimv/db/tagtree'
