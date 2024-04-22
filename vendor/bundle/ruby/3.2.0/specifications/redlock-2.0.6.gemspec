# -*- encoding: utf-8 -*-
# stub: redlock 2.0.6 ruby lib

Gem::Specification.new do |s|
  s.name = "redlock".freeze
  s.version = "2.0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Leandro Moreira".freeze]
  s.date = "2023-10-30"
  s.description = "Distributed lock using Redis written in Ruby. Highly inspired by https://github.com/antirez/redlock-rb.".freeze
  s.email = ["leandro.ribeiro.moreira@gmail.com".freeze]
  s.homepage = "https://github.com/leandromoreira/redlock-rb".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Distributed lock using Redis written in Ruby.".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<redis-client>.freeze, [">= 0.14.1", "< 1.0.0"])
  s.add_development_dependency(%q<connection_pool>.freeze, ["~> 2.2"])
  s.add_development_dependency(%q<coveralls>.freeze, ["~> 0.8"])
  s.add_development_dependency(%q<json>.freeze, [">= 2.3.0", "~> 2.3.1"])
  s.add_development_dependency(%q<rake>.freeze, [">= 11.1.2", "~> 13.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3", ">= 3.0.0"])
end
