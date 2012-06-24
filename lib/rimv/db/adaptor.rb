module Rimv
	module DB
		# Namespace for database adaptors
		module Adaptor
			include Rimv

			# Utility function for adaptors;
			# Add file(s) into the database
			def addfile path, base=false
				@base = path.sub(/\/*$/,'') if base
				begin
					if File.directory?(path)
						Enumerator.new(Dir, :foreach, path).collect do |file|
							next if %w<. ..>.include?(file)
							verbose(1).puts "adding directory `#{path}/#{file}'"
							addfile("#{path}/#{file}")
						end.compact.flatten
					elsif File.file?(path)
						img = Gtk::Image.new(path)
						if img.pixbuf || img.pixbuf_animation
							File.open(path) do |file|
								verbose(1).puts {"adding file `#{path}'"}
								hash = addimage(path,file.read)
								if @base
									verbose(3).puts "tag base = #{@base}"
									tag = File.dirname(path.sub(/^#{Regexp.escape(@base)}\/*/,''))
									unless tag == '.'
										addtag hash, tag
									end
								elsif not @@tag.empty?
									@@tag.each do |tag|
										verbose(3).puts "tagging `#{path}'(#{hash}) as `#{tag}'"
										addtag hash, tag
									end
								end
								return hash
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

			# Retrieve all existing tags (to be defined)
			def tags
				raise NotImplementedError
			end

			# Retrieve the max length among the tags
			def tags_max_length
				tags.collect do |tag|
					tag.to_s.length
				end.max || 0
			end

			# Return enumerator over every hash-tags pair
			def hashtags
				enum_for(:each_hash_tags)
			end

			# Create instance of Gtk::Image
			def getimage hash
				begin
					loader = Gdk::PixbufLoader.new
					loader.last_write(getimage_bin(hash))
					return Gtk::Image.new(loader.pixbuf)
				rescue Gdk::PixbufError
					if $!.message.include? 'Application transferred too few scanlines'
						return Gtk::Image.new loader.pixbuf
					end
					$!.message.concat("\nhash was `#{hash}'")
					raise $!
				end
			end
		end
	end
end

require 'rimv/db/adaptor/sqlite3.rb'
