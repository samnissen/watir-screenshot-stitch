lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "watir-screenshot-stitch/version"

Gem::Specification.new do |spec|
  spec.name          = "watir-screenshot-stitch"
  spec.version       = WatirScreenshotStitch::VERSION
  spec.authors       = ["Sam Nissen", "Sandeep Singh"]
  spec.email         = ["scnissen@gmail.com", "sandeepnagra@gmail.com"]

  spec.summary       = %q{Extends Watir to take stitched-together screenshots of full web pages.}
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/samnissen/watir-screenshot-stitch"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
    # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
    # raise "RubyGems 2.0 or newer is required to protect against " \
      # "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", "~> 3.10"
  spec.add_development_dependency "chunky_png", "~> 1.4"

  spec.required_ruby_version = '>= 2.3.0'

  spec.add_dependency "rubyzip", "~> 2.3"
  spec.add_dependency "watir", "~> 7.1"
  spec.add_dependency "mini_magick", "~> 4.11"
  spec.add_dependency "os", "~> 1.1"
  spec.add_dependency "binding_of_caller", "~> 1.0"
end
