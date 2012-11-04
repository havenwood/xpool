# -*- encoding: utf-8 -*-
require File.expand_path('../lib/xpool/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rob Gleeson"]
  gem.email         = ["rob@flowof.info"]
  gem.description   = %q{Write a gem description}
  gem.summary       = %q{Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "xpool"
  gem.require_paths = ["lib"]
  gem.version       = XPool::VERSION
  gem.add_runtime_dependency "iprocess", "~> 3.1"
end
