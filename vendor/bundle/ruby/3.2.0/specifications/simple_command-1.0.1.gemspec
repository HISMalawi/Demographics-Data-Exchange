# -*- encoding: utf-8 -*-
# stub: simple_command 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "simple_command".freeze
  s.version = "1.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrea Pavoni".freeze]
  s.date = "2022-04-28"
  s.description = "Easy way to build and manage commands (service objects)".freeze
  s.email = ["andrea.pavoni@gmail.com".freeze]
  s.homepage = "http://github.com/nebulab/simple_command".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.5.9".freeze
  s.summary = "Easy way to build and manage commands (service objects)".freeze

  s.installed_by_version = "3.5.9".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.1".freeze])
end
