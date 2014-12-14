#
# Copyright (C) Katsuhiko Nishimra 2010, 2011, 2012, 2014.
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

require 'rimv/db/adaptor'

module Rimv
	module DB
		class Adaptor
			# Database adaptor class using a SQLite3 backend
			class SQLite3 < Adaptor
				require 'sqlite3'
				require 'digest/md5'

				include ::SQLite3

				private
				# Private method
				def self.new *args
					super
				end
				private_class_method :new

				# Creates new adaptor.
				# new is a private class method.
				def initialize db_file=nil
					@db_file = db_file || "#{ENV['HOME']}/.imv.sqlite3"
					@db = Database.new(@db_file)
					if tables.empty?
						create_tables
					end
				end

				public
				# Execute given block with an opened database and
				# ensure it is closed
				def self.open db_file=nil
					db = new db_file
					begin
						yield db
					ensure
						begin
							db.close
						rescue SQLite3::BusyException
							$stderr.puts 'Aborting running query!'
						end
					end
				end

				# Fetch table list from the database
				def tables
					@db.execute(<<SQL)
SELECT name FROM sqlite_master WHERE type='table'
UNION ALL SELECT name FROM sqlite_temp_master WHERE type='table'
SQL
				end

				# Create tables for this application
				def create_tables
					transaction do
						@db.execute(<<SQL)
CREATE TABLE "img"
            (hash TEXT PRIMARY KEY NOT NULL,
             img NOT NULL, score INTEGER NOT NULL DEFAULT 0,
             added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
             last_displayed_at TIMESTAMP DEFAULT NULL);
SQL
            @db.execute(<<SQL)
CREATE TABLE "name"
             (hash TEXT NOT NULL, name TEXT NOT NULL,
              PRIMARY KEY(hash, name));
SQL
            @db.execute(<<SQL)
CREATE TABLE "tag"
             (hash TEXT NOT NULL, tag TEXT NOT NULL,
              PRIMARY KEY(hash, tag));
SQL
					end
				end

				# Close the database
				def close
					@db.close
				end

				# Add an image to the database
				def addimage name, img
					name, img = name.to_s, img.to_s
					hash = DB.digest img
					transaction do
						@db.execute(<<-SQL, :hash => hash, :img => Blob.new(img), :score => Application.score || 0)
INSERT INTO img (hash, img, score)
SELECT :hash, :img, :score
WHERE NOT EXISTS (SELECT 1 FROM img WHERE hash=:hash);
						SQL
						@db.execute(<<-SQL, :hash => hash, :name => File.basename(name) )
INSERT INTO name (hash, name)
SELECT :hash, :name
WHERE NOT EXISTS (SELECT 1 FROM name WHERE hash=:hash AND name=:name);
						SQL
					end and hash
				end

				# Add a tag to an image specified by hash
				def addtag hash, tag
					verbose(1).puts "tagging image `#{hash} as `#{tag}'"
					@db.execute(<<-SQL, :hash => hash.to_s, :tag => tag.to_s)
INSERT INTO tag (hash, tag)
SELECT :hash, :tag
WHERE NOT EXISTS (SELECT 1 FROM tag WHERE hash=:hash AND tag = :tag);
					SQL
				end

				# Delete a tag from an image specified by hash(no implementation)
				def deltag hash, tag
					verbose(1).puts "untagging image `#{hash} as `#{tag}'"
					@db.execute(<<-SQL, :hash => hash.to_s, :tag => tag.to_s)
DELETE FROM tag
WHERE hash=:hash and tag=:tag
					SQL
				end

				# Read image binary data from db
				def getimage_bin hash
					@db.get_first_value(<<-SQL,hash.to_s)
SELECT img
FROM img
WHERE hash = ?
LIMIT 1
					SQL
				end

				# Get hashes of all the images that satisfies the given condition
				def getallhash
					# TODO: purge and reuse the condition check clause
					where,arg =
						case Application.score
						when nil
							['',[]]
						when Integer
							['WHERE score = ?', [Application.score]]
						when Range
							['WHERE score BETWEEN ? AND ?', [Application.score.begin, Application.score.last]]
						else
							raise ScriptError
						end
					@db.execute(<<-"SQL", *arg).flatten
SELECT hash
FROM img
					#{where}
					SQL
				end

				# enumerate all the hash and tags
				def each_hash_tags
					@db.execute(<<-SQL) {|hash, tags| yield hash, (tags||'').split('|').uniq}
SELECT img.hash, group_concat(tag,'|')
FROM (img LEFT JOIN tag ON img.hash = tag.hash)
	LEFT JOIN name ON img.hash = name.hash
GROUP BY img.hash
ORDER BY min(name.name)
					SQL
				end

				#Retrieve all existing tags
				def tags
					@db.execute(<<SQL).collect(&:first)
SELECT tag
FROM tag
GROUP BY tag
SQL
				end

				#Execute block in a transaction
				def transaction
					if @db.transaction_active?
						yield
					else
						@db.transaction do
							yield
						end
					end
				end
			end
		end
	end
end
