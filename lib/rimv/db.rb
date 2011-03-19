module Rimv
	class DB
		include Rimv

		require 'sqlite3'
		require 'digest/md5'

		include SQLite3

		private_class_method :new

		public
		def self.open
			db = new
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

		@@db_file = "#{ENV['HOME']}/.imv.sqlite3"

		def self.db_file
			@@db_file
		end

		def self.db_file= db_file
			@@db_file = db_file
		end

		def initialize
			@db = Database.new(self.class.db_file)
		end

		def close
			@db.close
		end

		def addimage name, img
			raise TypeError unless img.kind_of?(String)
			hash = Digest::MD5.digest(img).unpack('h*').first
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

		def addfile path, base=false
			@base = path.sub(/\/*$/,'') if base
			begin
				if File.directory?(path)
					Dir.foreach(path) do |file|
						next if %w<. ..>.include?(file)
						verbose(1).puts "adding directory `#{path}/#{file}'"
						addfile("#{path}/#{file}")
					end
				elsif File.file?(path)
					img = Gtk::Image.new(path)
					if img.pixbuf || img.pixbuf_animation
						File.open(path) do |file|
							verbose(1).puts "adding file `#{path}'"
							hash = addimage(path,file.read)
							if @base
								verbose(3).puts "tag base = #{@base}"
								tag = File.dirname(path.sub(/^#{Regexp.escape(@base)}\/*/,''))
								unless tag == '.'
									addtag hash, tag
								end
							elsif @@tag
								verbose(3).puts "tagging `#{path}'(#{hash}) as `#{@@tag}'"
								addtag hash, @@tag
							end
						end
					else
						$stderr.puts "`#{path}' is not a image supported by gtk!"
						verbose(2).puts "image            = #{img.inspect}"
						verbose(2).puts "pixbuf           = #{img.pixbuf.inspect}"
						verbose(2).puts "pixbuf_animation = #{img.pixbuf_animation.inspect}"
					end
				else
					$stderr.puts "file `#{path}' does not exist!"
				end
			ensure
				@base = nil if base
			end
		end

		def addtag hash, tag
			verbose(1).puts "tagging image `#{hash} as `#{tag}'"
			@db.execute(<<-SQL, :hash => hash, :tag => tag)
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
	end
end

require 'rimv/db/tagtree'
