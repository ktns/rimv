require 'rimv/db/adaptor/sqlite3.rb'

module Rimv
	module DB
		@@adaptor=Adaptor::SQLite3
	end
end

require 'rimv/db/tagtree'
