# coding: utf-8
require File.expand_path('../lib/egon/version', __FILE__)
require 'date'

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = "egon"
  s.version       = Egon::VERSION
  s.authors	  = ['Egon and Fusor team']
  s.email         = ['foreman-dev+egon@googlegroups.com']
  s.summary       = %q{A library on top of Fog that encapsulates TripleO deployment operations}
  s.description   = %q{}
  s.homepage      = 'https://github.com/fusor/egon'
  s.date          = Date.today.to_s
  s.license       = 'GPL-3.0+'

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|s|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.7"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "fog", "~> 1.29.0"
end
