# frozen_string_literal: true

RSpec.describe Sparrow::CloudBuild::Build do
  let(:data) { JSON.parse(fixture(*names)) }
  let(:build) { described_class.new(data) }

  describe "status" do
    shared_examples "status" do |status|
      it "#status returns #{status}" do
        expect(build.status).to eq(status)
      end
    end

    shared_examples "queued" do |json|
      let(:names) { %W[builds status queued #{json}] }

      it_behaves_like "status", "QUEUED"
    end

    describe "queued github_app.json" do
      it_behaves_like "queued", "github_app.json"
    end

    shared_examples "working" do |json|
      let(:names) { %W[builds status working #{json}] }

      it_behaves_like "status", "WORKING"
    end

    describe "working github_app.json" do
      it_behaves_like "working", "github_app.json"
    end

    shared_examples "failure" do |json|
      let(:names) { %W[builds status failure #{json}] }

      it_behaves_like "status", "FAILURE"
    end

    describe "failure github_app.json" do
      it_behaves_like "failure", "github_app.json"
    end

    shared_examples "success" do |json|
      let(:names) { %W[builds status success #{json}] }

      it_behaves_like "status", "SUCCESS"

      it "#success? returns true" do
        expect(build.success?).to be(true)
      end

      it "#log_url" do
        url = "https://console.cloud.google.com/gcr/builds/02200e9c-0f7a-48c0-8050-5dcc60d3e310?project=918090106759"
        expect(build.log_url).to eq(url)
      end

      it "#tags" do
        expect(build.tags).to eq([
          "trigger-e9ba2adc-297b-4c79-9305-3fc6c3768db5",
        ])
      end

      it "#repo_source? returns master" do
        expect(build.repo_source?).to be(true)
      end
    end

    describe "success github_app.json" do
      it_behaves_like "success", "github_app.json"
    end
  end

  describe "branch" do
    shared_examples "master" do |json|
      let(:names) { %W[builds branch master #{json}] }

      it "#branch returns master" do
        expect(build.branch).to eq("master")
      end

      it "#master_branch? returns true" do
        expect(build.master_branch?).to be(true)
      end
    end

    describe "master github_app.json" do
      it_behaves_like "master", "github_app.json"
    end
  end

  describe "source" do
    describe "storage.json" do
      let(:names) { %w[builds source storage.json] }

      it "#repo_source? returns master" do
        expect(build.repo_source?).to be(false)
      end
    end
  end

  describe "#failed?" do
    let(:names) { %w[builds status failure github_app.json] }

    it "is true for every failed status" do
      %w[FAILURE INTERNAL_ERROR TIMEOUT EXPIRED].each do |status|
        data["status"] = status
        expect(build.failed?).to be(true)
      end
    end

    it "is false for CANCELLED and SUCCESS" do
      %w[CANCELLED SUCCESS].each do |status|
        data["status"] = status
        expect(build.failed?).to be(false)
      end
    end
  end

  describe "#github_repo" do
    context "with github_app.json without REPO_FULL_NAME" do
      let(:names) { %w[builds status success github_app.json] }

      it "returns nil" do
        expect(build.github_repo).to be_nil
      end
    end

    context "with REPO_FULL_NAME" do
      let(:names) { %w[builds status success github_app.json] }

      before { data["substitutions"]["REPO_FULL_NAME"] = "anipos/sparrow" }

      it "prefers REPO_FULL_NAME" do
        expect(build.github_repo).to eq("anipos/sparrow")
      end
    end
  end

  describe "#to_json" do
    let(:names) { %w[builds status success github_app.json] }

    it "does not raise error" do
      expect { build.to_json }.not_to raise_error
    end
  end
end
