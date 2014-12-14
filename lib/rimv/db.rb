#
# Copyright (C) Katsuhiko Nishimra 2010, 2011, 2012.
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
