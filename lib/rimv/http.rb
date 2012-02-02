require 'rubygems'
require 'net/http'
require 'uri'
require 'hpricot'

module Rimv
	module HTTP
		class Entity
			def initialize uri, options={}
				if options
					unless options.kind_of?(Hash)
						raise TypeError 'Expected Hash, but %s' % options.class
					end
					@referer = options[:referer].freeze
				end
				@uri = URI.parse(uri).freeze
				unless @uri.scheme == 'http'
					raise 'Specified scheme `%s\' is not http!' % @uri.scheme
				end
				case header.content_type
				when 'text/html'
					self.extend Page
				when %r|^image/|
					self.extend Img
				end
			end

			attr_reader :referer, :uri

			def start &block
				raise ArgumentError, 'No block given!' unless block
				Net::HTTP.start(@uri.host, @uri.port, &block)
			end

			def header
				@header or @header = start do |http|
					http.head(@uri.path, request_header)
				end
			end

			def body
				@body or @body = start do |http|
					res = http.get(@uri.path, request_header)
					res.body
				end
			end

			def request_header
				hdr = {}
				if @referer
					hdr['Referer'] = @referer.to_s
				end
				return hdr
			end
		end

		module Page
			include Enumerable
			def doc
				@doc or @doc = Hpricot.parse(body)
			end

			def each &block
				if block
					doc.search('img').each do |img|
						unless href = img['href']
							href = img.parent['href']
						end
						if href
							ent = Entity.new(href,:referer => @uri)
							if ent.kind_of? Img
								yield ent
							end
						end
					end
				else
					Enumerator.new(self, :each)
				end
			end
		end

		module Img
		end
	end
end
