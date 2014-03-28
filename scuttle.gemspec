$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'scuttle/version'

Gem::Specification.new do |s|
  s.name     = "scuttle"
  s.version  = ::Scuttle::VERSION
  s.authors  = ["Cameron Dutro"]
  s.email    = ["camertron@gmail.com"]
  s.homepage = "https://github.com/camertron"

  s.description = s.summary = "A library for transforming raw SQL statements into ActiveRecord/Arel queries. Ruby wrapper and tests for scuttle-java."

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true

  s.add_dependency "coderay", "~> 1.1.0"

  s.require_path = 'lib'
  s.files = Dir["{lib,spec,vendor}/**/*", "Gemfile", "History.txt", "LICENSE", "README.md", "Rakefile", "scuttle.gemspec"]
end
