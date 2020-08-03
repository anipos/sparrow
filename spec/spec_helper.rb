# frozen_string_literal: true

# > Load and launch SimpleCov at the very top of your test/test_helper.rb
# https://github.com/colszowka/simplecov/blob/c7690fcd94a75fa61dc843eefd07d4081716f95d/README.md
require "simplecov"
SimpleCov.start "test_frameworks" do
  track_files "lib/**/*.rb"
end

if ENV["CODECOV_TOKEN"]
  require "codecov"
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require "bundler/setup"
require "sparrow"
require "vcr"
require "webmock/rspec"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random
  Kernel.srand config.seed

  config.before(:all) do
    # Supress logging.
    Sparrow.instance_eval do
      @logger = Ougai::Logger.new("/dev/null")
    end
  end
end

VCR.configure do |config|
  config.configure_rspec_metadata!

  config.cassette_library_dir = "spec/fixtures/vcr"

  config.hook_into :webmock

  config.filter_sensitive_data("<GITHUB_TOKEN>") do |interaction|
    headers = interaction.request.headers["Authorization"]
    headers&.first
  end
end

def fixture(*name)
  File.read(File.join("spec", "fixtures", File.join(*name)))
end
