# frozen_string_literal: true

RSpec.describe Sparrow::Jobs::GitOps::Rewrite do
  let(:build) do
    Sparrow::CloudBuild::Build.new(
      JSON.parse(fixture("builds", "branch", "master.json"))
    )
  end

  let(:rewrite) do
    described_class.new(
      build: build,
      name: "spec",
      source_repo: "anipos/sparrow",
      config_repo: "anipos/sparrow",
      erb_path: "spec/fixtures/git_ops/template.erb",
      out_path: "spec/fixtures/git_ops/rewritten"
    )
  end

  it "creates a pull request" do
    VCR.use_cassette("create_pull_request") do
      pr = rewrite.run

      expect(pr.title).to eq("Update tag to #{build.commit_sha}")
    end
  end

  it "do nothing when the same pull request exists" do
    VCR.use_cassette("pull_request_exists") do
      pr = rewrite.run

      expect(pr).to be_nil
    end
  end
end
