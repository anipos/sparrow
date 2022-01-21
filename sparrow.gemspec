# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sparrow/version"

Gem::Specification.new do |spec|
  spec.name          = "sparrow"
  spec.version       = Sparrow::VERSION
  spec.authors       = ["Shouichi Kamiya"]
  spec.email         = ["shouichi.kamiya@gmail.com"]

  spec.summary       = "Cloud Build events consumer."
  spec.description   = <<~DESC
    Reacts to cloud build events and does the work such as sending slack
    notifications and rewriting kubernetes manifests.
  DESC
  spec.homepage = "https://github.com/anipos/sparrow"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the
  # 'allowed_push_host' to allow pushing to a single host or delete this
  # section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
    spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.required_ruby_version = ">= 2.6.0"

  # Specify which files should be added to the gem when it is released.  The
  # `git ls-files -z` loads the files in the RubyGem that have been added into
  # git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "google-cloud-pubsub", ">= 1.6", "< 3.0"
  spec.add_dependency "octokit", "~> 4.15"
  spec.add_dependency "ougai", ">= 1.8", "< 3.0"
  spec.add_dependency "sentry-ruby", ">= 4", "< 6"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "codecov", "~> 0.6.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.4"
  spec.add_development_dependency "rubocop", "~> 0.74"
  spec.add_development_dependency "rubocop-performance", "~> 1.5"
  spec.add_development_dependency "rubocop-rspec", "~> 1.38"
  spec.add_development_dependency "simplecov", "~> 0.17"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "webmock", "~> 3.8"
  spec.add_development_dependency "yard", "~> 0.9"
end
