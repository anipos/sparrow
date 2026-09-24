# frozen_string_literal: true

RSpec.describe Sparrow::Jobs::Slack do
  let(:webhook) { "https://hooks.slack.com/services/T0/B0/XXX" }
  let(:slack_user_id) { "@U024BE7LH" }
  let(:posted_bodies) { [] }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("SPARROW_SLACK_WEBHOOK", nil).and_return(webhook)

    stub_request(:post, webhook).to_return do |request|
      posted_bodies << JSON.parse(request.body)
      { status: 200 }
    end
  end

  def build_data(*names)
    JSON.parse(fixture("builds", *names))
  end

  def message_for(data)
    instance_double("message", data: data.to_json)
  end

  def blocks
    expect(posted_bodies.size).to eq(1)
    posted_bodies.first["blocks"]
  end

  it "posts the build as a block kit message" do
    data = build_data("status", "success", "github_app.json")
    data["substitutions"]["REPO_FULL_NAME"] = "anipos/sparrow"

    described_class.new("mention" => { "SUCCESS" => slack_user_id }).run(message_for(data))

    expect(WebMock)
      .to have_requested(:post, webhook)
      .with(headers: { "Content-Type" => "application/json" })
    expect(blocks).to eq(
      [
        {
          "type" => "header",
          "text" => { "type" => "plain_text", "text" => "Build SUCCESS" }
        },
        {
          "type" => "section",
          "fields" => [
            { "type" => "mrkdwn", "text" => "*Repository:*\nanipos/sparrow" },
            { "type" => "mrkdwn", "text" => "*Tags:*\n#{data['tags'].join(', ')}" },
            { "type" => "mrkdwn", "text" => "<#{slack_user_id}>" },
          ]
        },
        {
          "type" => "actions",
          "elements" => [
            {
              "type" => "button",
              "text" => { "type" => "plain_text", "text" => "View build" },
              "url" => data["logUrl"],
              "style" => "primary"
            },
            {
              "type" => "button",
              "text" => { "type" => "plain_text", "text" => "View commit" },
              "url" => "https://github.com/anipos/sparrow/commit/#{data['substitutions']['COMMIT_SHA']}",
              "style" => "primary"
            },
          ]
        },
      ]
    )
  end

  it "omits the commit link when the build has no REPO_FULL_NAME" do
    described_class.new.run(message_for(build_data("status", "success", "github_app.json")))

    expect(blocks[1]["fields"][0]["text"]).to eq("*Repository:*\nsparrow")
    expect(blocks[2]["elements"].map { _1["text"]["text"] }).to eq(["View build"])
  end

  it "omits the mention when no mention is configured for the status" do
    described_class.new("mention" => { "FAILURE" => slack_user_id })
      .run(message_for(build_data("status", "success", "github_app.json")))

    expect(blocks[1]["fields"].map { _1["text"] }).to all(start_with("*"))
  end

  it "posts failed builds in danger style" do
    described_class.new.run(message_for(build_data("status", "failure", "github_app.json")))

    expect(blocks[2]["elements"].map { _1["style"] }.uniq).to eq(["danger"])
  end

  it "treats TIMEOUT as FAILURE for filtering, mention and style" do
    data = build_data("status", "failure", "github_app.json")
    data["status"] = "TIMEOUT"

    described_class.new("only" => %w[FAILURE], "mention" => { "FAILURE" => slack_user_id })
      .run(message_for(data))

    expect(blocks[0]["text"]["text"]).to eq("Build TIMEOUT")
    expect(blocks[1]["fields"].last["text"]).to eq("<#{slack_user_id}>")
    expect(blocks[2]["elements"].map { _1["style"] }.uniq).to eq(["danger"])
  end

  it "posts QUEUED and WORKING builds by default" do
    described_class.new.run(message_for(build_data("status", "queued", "github_app.json")))
    described_class.new.run(message_for(build_data("status", "working", "github_app.json")))

    expect(posted_bodies.map { _1["blocks"][0]["text"]["text"] })
      .to eq(["Build QUEUED", "Build WORKING"])
  end

  it "does not post when the build is not from a repo source" do
    described_class.new.run(message_for(build_data("source", "storage.json")))

    expect(WebMock).not_to have_requested(:post, webhook)
  end

  it "does not post when the status is not in `only`" do
    described_class.new("only" => %w[SUCCESS FAILURE])
      .run(message_for(build_data("status", "working", "github_app.json")))

    expect(WebMock).not_to have_requested(:post, webhook)
  end

  it "raises an error the gateway retries when slack is unreachable" do
    stub_request(:post, webhook).to_timeout

    expect { described_class.new.run(message_for(build_data("status", "success", "github_app.json"))) }
      .to raise_error do |error|
        expect(Sparrow::PubSubGateway::RETRYABLE_ERRORS).to include(error.class)
      end
  end

  it "does not raise when slack rejects the message" do
    stub_request(:post, webhook).to_return(status: 500)

    expect { described_class.new.run(message_for(build_data("status", "success", "github_app.json"))) }
      .not_to raise_error
    expect(WebMock).to have_requested(:post, webhook)
  end
end
