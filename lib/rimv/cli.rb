require 'rimv'

module ::Rimv::CLI
	include ::Rimv
	MODES={
			'add'=>'add image(s) to database',
			'view'=>'view images in database'
	}

	def self.parse argv=ARGV
		mode      = nil
		path_tag  = false
		tag       = []
		random    = false
		score     = nil
		verbosity = 0
		opt = OptionParser.new
		MODES.each do |mode,desc|
			opt.on('-'+mode[0,1],'--'+mode,desc) do |v|
				if Rimv.mode
					$stderr.printf("multiple mode option specified!('%s' after '%s')\n",
												 mode, Rimv.mode)
					abort
				else
					Rimv.mode = mode
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
					 'specify tag of images to be added (or deleted with TAG-)'){|tag| tag.concat tag.split(',')}

		opt.parse! argv

		abort 'path_tag and tag option is mutually exclusive!' if path_tag && tag

		return Application.new mode, path_tag, tag, random, score, verbosity
	end
end
