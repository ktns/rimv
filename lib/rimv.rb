$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Rimv
	APP_NAME = "rimv"
	Version  = '0.1.4'

	require "gtk2"

	@@mode      = nil
	@@path_tag  = false
	@@tag       = nil
	@@random    = false
	@@score     = nil
	@@verbosity = 0

	module Logo
		@@base  = Gdk::Pixbuf.new(File.dirname(__FILE__) + '/../asset/logo.xpm')
		@@sizes = Hash[
			*([8,16,32,64].collect do |size|
				[size, @@base.scale(size, size)]
			end.flatten)
		]

		def self.icons
			@@sizes.values
		end

		def self.icon size
			@@sizes[size]
		end
	end

	class <<self
		def verbosity
			@@verbosity
		end

		def verbosity= new_verbosity
			@@verbosity = new_verbosity
		end
	end

	# Virtural IO class for log
	class VerboseMessenger
		include Rimv

		# Create logger with specified verbosity level
		def initialize verbose_level
			raise ScriptError, "invalid verbose level `#{num}'!" unless verbose_level > 0
			@verbose_level = verbose_level
		end

		# Pass through method call to $stdout if the specified
		# verbosity level exceeds the application verbosity level
		def method_missing name, *args, &block
			if @@verbosity >= @verbose_level
				if block
					$stdout.send(name, *block.call(*args))
				else
					$stdout.send(name, *args)
				end
			else
				unless IO.method_defined?(name)
					raise NoMethodError.new("method `#{name}' is undefined in IO class!", name, arg)
				end
			end
		end
	end

	#Returns VerboseMessenger with specified versbosity level
	def verbose verbose_level
		VerboseMessenger.new(verbose_level)
	end

	Enumerator = (::Enumerator rescue Enumerable::Enumerator)
end

require 'rimv/db'
require 'rimv/main_win'
