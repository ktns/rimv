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

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# Application Namespace
module Rimv
	#Name of this application
	APP_NAME = "rimv"
	#Version of this application
	Version  = IO.read(File.join(File.dirname(__FILE__),%w<.. VERSION>)).rstrip

	require "gtk2"

	# Namespace for the application logo
	module Logo
		@@base  = Gdk::Pixbuf.new(File.dirname(__FILE__) + '/../asset/logo.png')
		@@sizes = Hash[
			*([8,16,32,64].collect do |size|
			[size, @@base.scale(size, size)]
			end.flatten)
		]

		# Returns an array containing icons of various sizes
		def self.icons
			@@sizes.values
		end

		# Returns an icon of the specified size
		def self.icon size
			@@sizes[size]
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
			if Rimv::Application.verbosity >= @verbose_level
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

	# Instance representing the application
	class Application
		def initialize mode = nil, path_tag = false, tag = [], random = false, score = nil, verbosity = 0
			@mode, @path_tag, @tag, @random, @score, @verbosity = mode, path_tag, tag, random, score, verbosity
			@@application = self
		end

		# Get/Set application parameters
		attr_accessor :mode, :path_tag, :tag, :random, :score, :verbosity

		def run
			case @mode
			when 'add'
				raise 'No file to add!' if ARGV.empty?
				raise "Non-integer score is not acceptable in `add' mode!" unless ! @score || @score.kind_of?(Integer)
				DB.open do |db|
					ARGV.each do |name|
						db.addfile(name, @path_tag)
					end
				end
			when 'view',nil
				DB.open do |db|
					abort 'No Image!' if (hashlist = db.getallhash).empty?
					main_win = MainWin.new(db)
					Gtk.main
				end
			else
				raise NotImplementedError, "Unexpected mode `#{mode}'!"
			end
		end

		def self.tag
			@@application.tag
		end

		def self.random
			@@application.random
		end

		def self.random= val
			@@application.random = val
		end

		def self.score
			@@application.score
		end

		def self.verbosity
			@@application.verbosity rescue 0
		end
	end

	# Workaround for Enumerator in ruby-1.8.x and 1.9.x
	Enumerator = (::Enumerator rescue Enumerable::Enumerator)
end

require 'rimv/db'
require 'rimv/main_win'
