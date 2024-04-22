# -*- encoding: utf-8 -*-
# stub: whitesimilarity 0.0.2 ruby lib
# stub: ext/whitesimilarity/extconf.rb

Gem::Specification.new do |s|
  s.name = "whitesimilarity".freeze
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jeremy Fairbank".freeze]
  s.date = "2014-01-14"
  s.description = "An implementation of the White Similarity Algorithm in C".freeze
  s.email = ["elpapapollo@gmail.com".freeze]
  s.extensions = ["ext/whitesimilarity/extconf.rb".freeze]
  s.files = ["ext/whitesimilarity/extconf.rb".freeze]
  s.homepage = "https://github.com/jfairbank/whitesimilarity".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.1".freeze
  s.summary = "White Similarity Algorithm".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
end
