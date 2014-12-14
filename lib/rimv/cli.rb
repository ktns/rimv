require 'rimv'

module ::Rimv::CLI
	include ::Rimv
	MODES={
			'add'=>'add image(s) to database',
			'view'=>'view images in database'
	}

	class ParseError < RuntimeError
	end

	def self.parse argv=ARGV
		mode      = nil
		path_tag  = false
		tags      = []
		random    = false
		score     = nil
		verbosity = 0
		opt = OptionParser.new
		MODES.each do |m,desc|
			opt.on('-'+m[0,1],'--'+m,desc) do |v|
				if mode
					raise ParseError, "multiple mode option specified!('%s' after '%s')" % [m, mode]
				else
					mode = m
				end
			end
		end
		opt.on('--verbose=[VERBOSITY]', 'verbosely report information') do |v|
			verbosity = v.nil? ? 1 : v.to_i
			raise "invalid verbosity `#{v}'!" unless verbosity > 0
			verbose(1).puts "verbosity = #{verbosity}"
		end

		opt.on('-s=VAL', '--score=VAL',
					 'score of the image to be displayed or added') {|val|
			if val =~ /\A(-?\d+)([+-])\Z/
				if $2 == '+'
					score = (eval $1)..1.0/0
				else
					score = -1.0/0..(eval $1)
				end
			else
				score = eval val
				unless [Integer,Range].any?{|cls| score.kind_of?(cls)}
					raise ArgumentError, "Can't parse score value string `#{val}'!"
				end
			end
		}

		opt.on('-r', '--random',
					 'randomize order of images to be displayed'){random=true}

		opt.on('-p', '--path-tag',
					 'tag image with directory name'){path_tag = true}

		opt.on('-t TAG', '--tag=TAG',
					 'specify tag of images to be added (or deleted with TAG-)'){|tag| tags.concat tag.split(',')}

		opt.parse! argv

		raise ParseError, 'path_tag and tag option is mutually exclusive!' if path_tag && !tags.empty?

		return Application.new mode, path_tag, tags, random, score, verbosity
	end
end
