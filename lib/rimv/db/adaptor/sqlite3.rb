require 'rimv/db/adaptor'

module Rimv
	module DB
		module Adaptor
			class SQLite3

				include Adaptor

				require 'sqlite3'
				require 'digest/md5'

				include ::SQLite3

				private_class_method :new

				public
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

				def initialize db_file=nil
					@db_file = db_file || "#{ENV['HOME']}/.imv.sqlite3"
					@db = Database.new(@db_file)
					if tables.empty?
						create_tables
					end
				end

				def tables
					@db.execute(<<SQL)
SELECT name FROM sqlite_master WHERE type='table' 
UNION ALL SELECT name FROM sqlite_temp_master WHERE type='table'
SQL
				end

				def create_tables
					@db.transaction do
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

				def close
					@db.close
				end

				def addimage name, img
					name, img = name.to_s, img.to_s
					hash = DB.digest img
					@db.transaction do |db|
						db.execute(<<-SQL, :hash => hash, :img => Blob.new(img), :score => @@score || 0)
INSERT INTO img (hash, img, score)
SELECT :hash, :img, :score
WHERE NOT EXISTS (SELECT 1 FROM img WHERE hash=:hash);
						SQL
						db.execute(<<-SQL, :hash => hash, :name => File.basename(name) )
INSERT INTO name (hash, name)
SELECT :hash, :name
WHERE NOT EXISTS (SELECT 1 FROM name WHERE hash=:hash AND name=:name);
						SQL
					end and hash
				end

				def addtag hash, tag
					verbose(1).puts "tagging image `#{hash} as `#{tag}'"
					@db.execute(<<-SQL, :hash => hash.to_s, :tag => tag.to_s)
INSERT INTO tag (hash, tag)
SELECT :hash, :tag
WHERE NOT EXISTS (SELECT 1 FROM tag WHERE hash=:hash AND tag = :tag);
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

		# Create instance of Gtk::Image
				def getimage hash
			# TODO: implementation without Tempfile
					require 'tempfile'
					tmp = Tempfile.new(APP_NAME)
					begin
						tmp.write getimage_bin(hash)
						tmp.close
						return Gtk::Image.new(tmp.path)
					ensure
						tmp.close(true)
					end
				end

				def getallhash
					where,arg =
						case @@score
						when nil
							['',[]]
						when Integer
							['WHERE score = ?', [@@score]]
						when Range
							['WHERE score BETWEEN ? AND ?', [@@score.begin, @@score.last]]
						else
							raise ScriptError
						end
					@db.execute(<<-"SQL", *arg).flatten
SELECT hash
FROM img
					#{where}
					SQL
				end

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
					@db.execute(<<SQL).collect(&:to_s)
SELECT tag
FROM tag
GROUP BY tag
SQL
				end
			end
		end
	end
end
