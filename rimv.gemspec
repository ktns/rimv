# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: rimv 0.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rimv"
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Katsuhiko Nishimra"]
  s.date = "2014-05-07"
  s.description = "Tag base image manager and viewer"
  s.email = "ktns.87@gmail.com"
  s.executables = ["rimv"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    "COPYING",
    "Gemfile",
    "Gemfile.lock",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "asset/logo.png",
    "bin/rimv",
    "lib/rimv.rb",
    "lib/rimv/db.rb",
    "lib/rimv/db/adaptor.rb",
    "lib/rimv/db/adaptor/sqlite3.rb",
    "lib/rimv/db/tagtree.rb",
    "lib/rimv/db/tagtree/leaf.rb",
    "lib/rimv/db/tagtree/node.rb",
    "lib/rimv/keyval.rb",
    "lib/rimv/main_win.rb",
    "lib/rimv/main_win/key_parser.rb",
    "lib/rimv/main_win/tagpopup.rb",
    "lib/rimv/size.rb",
    "lib/rimv/tagadd_win.rb",
    "rimv.gemspec",
    "spec/fixtures/hashtags.yml",
    "spec/rimv/db/adaptor/sqlite3_spec.rb",
    "spec/rimv/db/adaptor_spec.rb",
    "spec/rimv/db/tagtree/node/leaf_spec.rb",
    "spec/rimv/db/tagtree/node_spec.rb",
    "spec/rimv/db/tagtree_spec.rb",
    "spec/rimv/db_spec.rb",
    "spec/rimv/keyval_spec.rb",
    "spec/rimv/main_win/tagpopup_spec.rb",
    "spec/rimv/main_win_spec.rb",
    "spec/rimv/tagadd_win_spec.rb",
    "spec/rimv_spec.rb",
    "spec/spec_helper.rb",
    "tasks/db2fixture.rake"
  ]
  s.homepage = "http://github.com/ktns/rimv"
  s.licenses = ["GPLv3"]
  s.rubygems_version = "2.2.2"
  s.summary = "Tag base image manager and viewer"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sqlite3>, ["~> 1.3.9"])
      s.add_runtime_dependency(%q<gtk2>, ["~> 2.2.0"])
      s.add_development_dependency(%q<rdoc>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
    else
      s.add_dependency(%q<sqlite3>, ["~> 1.3.9"])
      s.add_dependency(%q<gtk2>, ["~> 2.2.0"])
      s.add_dependency(%q<rdoc>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
    end
  else
    s.add_dependency(%q<sqlite3>, ["~> 1.3.9"])
    s.add_dependency(%q<gtk2>, ["~> 2.2.0"])
    s.add_dependency(%q<rdoc>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
  end
end

