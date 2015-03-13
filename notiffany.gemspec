# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'notiffany/version'

Gem::Specification.new do |spec|
  spec.name          = "notiffany"
  spec.version       = Notiffany::VERSION
  spec.authors       = ["Cezary Baginski", "Rémy Coutable", "Thibaud Guillaume-Gentil"]
  spec.email         = ["cezary@chronomantic.net"]

  spec.summary       = %q{Notifier library (extracted from Guard project)}
  spec.description   = <<-EOF
    Wrapper libray for most popular notification
    libraries such as Growl, Libnotify, Notifu
  EOF

  spec.homepage      = "https://github.com/guard/notiffany"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    /^spec\//.match(f)
  end

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "nenv", "~> 0.1"
  spec.add_runtime_dependency "shellany", "~> 0.0"

  spec.add_development_dependency "bundler", "~> 1.7"
end
