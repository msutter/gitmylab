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

  spec.add_dependency "thor", "0.19.1"
  spec.add_dependency "activesupport", "4.2.0"
  spec.add_dependency "gitlab", "3.3.0"
  spec.add_dependency "git", "1.2.9.1"
  spec.add_dependency "open4", "1.3.4"
  spec.add_dependency "active_directory", "1.6.0"
  spec.add_dependency "net-ldap", "0.11"
  spec.add_dependency "configatron", "4.5.0"
  spec.add_dependency "ruby-progressbar", "1.7.1"
  spec.add_dependency "tty-spinner", "0.1.0"
  spec.add_dependency "command_line_reporter", "3.3.5"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~> 10.4"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-rescue"
end
