# -*- encoding: utf-8 -*-
# stub: activejob-uniqueness 0.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "activejob-uniqueness".freeze
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/veeqo/activejob-uniqueness/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/veeqo/activejob-uniqueness", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/veeqo/activejob-uniqueness" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rustam Sharshenov".freeze]
  s.date = "2023-10-30"
  s.description = "Ensure uniqueness of your ActiveJob jobs".freeze
  s.email = ["rustam@sharshenov.com".freeze]
  s.homepage = "https://github.com/veeqo/activejob-uniqueness".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Ensure uniqueness of your ActiveJob jobs".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activejob>.freeze, [">= 4.2", "< 7.2"])
  s.add_runtime_dependency(%q<redlock>.freeze, [">= 2.0", "< 3"])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.3.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 2.0"])
  s.add_development_dependency(%q<pry-byebug>.freeze, ["> 3.6.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.28"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 2.10"])
end
