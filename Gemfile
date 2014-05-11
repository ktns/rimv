source "http://rubygems.org"
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"
gem 'sqlite3', '~> 1.3'
gem 'gtk2'   , '~> 2.2'


# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "rdoc", '>= 4.1.1'
  gem "bundler", '~> 1.6'
  gem "jeweler", '~> 2.0'
end

group :test do
  gem "rspec", '~> 2.14'
  gem "simplecov", :require => false
end

group :debug do
  gem 'debugger', :platform => :ruby_19
  gem 'byebug', :platform => [:ruby_20, :ruby_21]
end
