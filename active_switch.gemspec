# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_switch/version"

Gem::Specification.new do |spec|
  spec.name          = "active_switch"
  spec.version       = ActiveSwitch::VERSION
  spec.authors       = ["Brendon Murphy"]
  spec.email         = ["xternal1+github@gmail.com"]

  spec.summary       = %q{Check that your scheduled tasks are still alive.}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/bemurphy/active_switch"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "mock_redis"

  # Redis is added as a development dependency and expects the parent application to set the dependency
  spec.add_development_dependency "redis"
end
