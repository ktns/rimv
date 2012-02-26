# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development, :test)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
$jeweler = Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "rimv"
  gem.homepage = "http://github.com/ktns/rimv"
  gem.license = "GPLv3"
  gem.summary = %Q{Tag base image manager and viewer}
  gem.description = %Q{Tag base image manager and viewer}
  gem.email = "ktns.87@gmail.com"
  gem.authors = ["Katsuhiko Nishimra"]
  # dependencies defined in Gemfile
end.jeweler
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rimv #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Dir['tasks/**/*.rake'].each { |t| load t }

%w<major minor patch>.each do |ver|
	begin 
		desc Rake::Task["version:bump:#{ver}"].comment + ', and Generate gemspec'
	rescue
	end
	task "version:up:#{ver}" => ["version:bump:#{ver}"] do
		git = Git.open(File.dirname(__FILE__))
		$jeweler.write_gemspec
		git.add $jeweler.gemspec_helper.path
		commit  = git.gcommit('HEAD')
		tree    = git.write_tree
		system 'git commit --amend -C HEAD'
	end
end
