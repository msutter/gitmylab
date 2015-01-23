# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gitmylab/version'

Gem::Specification.new do |spec|
  spec.name          = "gitmylab"
  spec.version       = Gitmylab::VERSION
  spec.authors       = ["Marc Sutter"]
  spec.email         = ["marc.sutter@swissflow.ch"]
  spec.summary       = %q{Gitlab access and projects Syncronisation.}
  spec.description   = %q{Gitlab access and projects Syncronisation.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  spec.add_dependency "gitlab"
  spec.add_dependency "git"
  spec.add_dependency "open4"
  spec.add_dependency "active_directory"
  spec.add_dependency "net-ldap"
  spec.add_dependency "configatron"
  spec.add_dependency "ruby-progressbar"
  spec.add_dependency "tty-spinner"
  spec.add_dependency "command_line_reporter"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
end
