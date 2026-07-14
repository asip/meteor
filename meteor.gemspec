# frozen_string_literal: true

require 'English'
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'meteor'

Gem::Specification.new do |spec|
  spec.name = 'meteor'
  spec.version = Meteor::VERSION
  spec.authors = ['Yasumasa Ashida']
  spec.email = 'ys.ashida@gmail.com'
  spec.description = 'A lightweight (X)HTML & XML parser'
  spec.summary = 'A lightweight (X)HTML & XML parser'
  spec.homepage = 'https://github.com/asip/meteor'
  spec.license = 'LGPL-2.1-only'

  spec.required_ruby_version = '>=3.0'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features|demo)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 4.0.16'
  # spec.add_development_dependency "rake"
end
