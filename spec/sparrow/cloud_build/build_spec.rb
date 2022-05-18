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

    describe "queued.json" do
      let(:names) { %w[builds status queued.json] }

      include_examples "status", "QUEUED"
    end

    describe "working.json" do
      let(:names) { %w[builds status working.json] }

      include_examples "status", "WORKING"
    end

    describe "failure.json" do
      let(:names) { %w[builds status failure.json] }

      include_examples "status", "FAILURE"
    end

    describe "success.json" do
      let(:names) { %w[builds status success.json] }

      include_examples "status", "SUCCESS"

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
  end

  describe "branch" do
    describe "master.json" do
      let(:names) { %w[builds branch master.json] }

      it "#branch returns master" do
        expect(build.branch).to eq("master")
      end

      it "#master_branch? returns true" do
        expect(build.master_branch?).to be(true)
      end
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

  describe "#to_json" do
    let(:names) { %w[builds status success.json] }

    it "does not raise error" do
      expect { build.to_json }.not_to raise_error
    end
  end
end
