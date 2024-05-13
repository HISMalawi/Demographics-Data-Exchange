# -*- encoding: utf-8 -*-
# stub: activerecord-import 1.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "activerecord-import".freeze
  s.version = "1.6.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Zach Dennis".freeze]
  s.date = "2024-03-15"
  s.description = "A library for bulk inserting data using ActiveRecord.".freeze
  s.email = ["zach.dennis@gmail.com".freeze]
  s.homepage = "https://github.com/zdennis/activerecord-import".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.5.9".freeze
  s.summary = "Bulk insert extension for ActiveRecord".freeze

  s.installed_by_version = "3.5.9".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 4.2".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
end
