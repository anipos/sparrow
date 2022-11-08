# frozen_string_literal: true

RSpec.describe Sparrow::Jobs::GitOps::Rewrite do
  shared_examples "rewrite_create_pull_request" do |json|
    let(:build) do
      Sparrow::CloudBuild::Build.new(
        JSON.parse(fixture("builds", "branch", "master", json))
      )
    end

    let(:rewrite) do
      described_class.new(
        build:,
        name: "spec",
        source_repo: "anipos/sparrow",
        config_repo: "anipos/sparrow",
        erb_path: "spec/fixtures/git_ops/template.erb",
        out_path: "spec/fixtures/git_ops/rewritten",
        bypass_pull_request: false
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

  describe "rewrite and make pr with github_legacy.json" do
    include_examples "rewrite_create_pull_request", "github_legacy.json"
  end

  describe "rewrite and make pr with github_app.json" do
    include_examples "rewrite_create_pull_request", "github_app.json"
  end

  shared_examples "rewrite_master_push" do |json|
    let(:build) do
      Sparrow::CloudBuild::Build.new(
        JSON.parse(fixture("builds", "branch", "master", json))
      )
    end

    let(:rewrite) do
      described_class.new(
        build:,
        name: "spec",
        source_repo: "anipos/sparrow",
        config_repo: "anipos/sparrow",
        erb_path: "spec/fixtures/git_ops/template.erb",
        out_path: "spec/fixtures/git_ops/rewritten",
        bypass_pull_request: true
      )
    end

    it "commit and push to master" do
      VCR.use_cassette("commit_master") do
        cm = rewrite.run

        expect(cm.message).to start_with("Update tag to #{build.commit_sha}")
      end
    end

    it "do nothing when the same commit exists" do
      VCR.use_cassette("master_commit_exist") do
        cm = rewrite.run

        expect(cm).to be_nil
      end
    end
  end

  describe "rewrite and commit to master with github_legacy.json" do
    include_examples "rewrite_master_push", "github_legacy.json"
  end

  describe "rewrite and commit to master with github_app.json" do
    include_examples "rewrite_master_push", "github_app.json"
  end
end
