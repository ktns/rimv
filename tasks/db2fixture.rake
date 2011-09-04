require 'rimv/db'

module Rimv::Task
	module Anonymizer
		class Hash
			def initialize
				@table=::Hash.new do |hash,key|
					hash[key]=succ
				end
			end

			def succ
				@table.size.to_s
			end

			def [] arg
				@table[arg]
			end
		end

		class Tag < Hash
			def succ
				t='a'
				@table.size.times{t=t.succ}
				t
			end

			def [] arg
				arg.split('/').collect do |tag|
					@table[tag]
				end.join('/')
			end
		end
	end
end

namespace :db do
	desc 'create fixtures from db'
	task :fixture do
		hash_an,tag_an =
			[Rimv::Task::Anonymizer::Hash,
				Rimv::Task::Anonymizer::Tag].collect(&:new)
		Rimv::DB.open do |db|
			destdir=ENV['DEST_DIR'] || '.'
			File.open("#{destdir}/hashtags.yml",'w') do |f|
				f.puts(db.tagenum.to_a.shuffle[0..99].collect do |hash, tags|
					[hash_an[hash],tags.collect{|t|tag_an[t]}]
				end.to_yaml)
			end
		end
	end
end
