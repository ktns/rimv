$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Rimv
	APP_NAME = "rimv"
	Version  = '0.0.4'

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

	class DummyIO
		def method_missing name, *arg
			unless IO.method_defined?(name)
				raise NoMethodError.new("method `#{name}' is undefined in IO class!", name, arg)
			end
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

	def verbose verbosity
		raise ScriptError, "invalid verbosity `#{num}'!" unless verbosity > 0
		if verbosity <= @@verbosity
			$stdout
		else
			DummyIO.new
		end
	end
end

require 'rimv/db'
require 'rimv/main_win'
