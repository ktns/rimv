begin
  require 'rspec'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  require 'rspec'
end

namespace :spec do
	RSpec::Core::RakeTask.new('rcov') do |t|
		t.pattern = 'spec/**/*_spec.rb'
		t.rcov = true
		t.rspec_opts = %w<-c>
		t.rcov_opts = Gem.path.collect do |p|
			['-x',p]
		end.flatten.concat(['-x', '^spec/'])
	end
end
