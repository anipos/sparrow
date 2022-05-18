# frozen_string_literal: true

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
