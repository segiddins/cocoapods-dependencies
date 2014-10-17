# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods_dependencies.rb'

Gem::Specification.new do |spec|
  spec.name          = "cocoapods-dependencies"
  spec.version       = Pod::Dependencies::VERSION
  spec.authors       = ["Samuel E. Giddins"]
  spec.email         = ["segiddins@segiddins.me"]
  spec.description   = %q{Shows a project's CocoaPods dependency graph.}
  spec.summary       = %q{Shows a project's CocoaPods dependency graph.}
  spec.homepage      = "https://github.com/segiddins/cocoapods-dependencies"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
