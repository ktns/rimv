require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/rimv'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'rimv' do
	self.developer 'Katsuhiko Nishimra', 'kat841@hotmail.com'
	self.post_install_message = 'PostInstall.txt'
	self.extra_rdoc_files << 'README.rdoc'
	self.extra_deps     = [['sqlite3-ruby','>= 1.2.3']]
	self.rubyforge_name = Rimv::APP_NAME
	self.version        = Rimv::Version
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

require 'rake/clean'
CLEAN << '.rbx'

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]
