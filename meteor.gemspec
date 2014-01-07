# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'meteor'

Gem::Specification.new do |spec|
  spec.name = %q{meteor}
  spec.version = Meteor::VERSION
  spec.authors = ["Yasumasa Ashida"]
  spec.email = %q{ys.ashida@gmail.com}
  spec.description = %q{A lightweight (X)HTML(5) & XML parser}
  spec.summary = %q{A lightweight (X)HTML(5) & XML parser}
  spec.homepage = %q{https://github.com/asip/meteor}
  spec.license = 'LGPLv2.1'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features|demo)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  #spec.add_development_dependency "rake"
  spec.has_rdoc = 'yard'

end
