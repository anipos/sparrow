# frozen_string_literal: true

RSpec.describe Sparrow::Jobs::Slack do
  let(:message) { instance_double("message") }
  let(:build) { instance_double("build") }
  let(:faraday) { instance_double("faraday") }
  let(:slack_user_id) { "@U024BE7LH" }

  it "#run does not raise an error" do
    slack = described_class.new(
      "mention" => {
        "SUCCESS" => slack_user_id
      }
    )

    expect(message).to receive(:data).and_return("{}")

    expect(slack).to receive(:build)
      .at_least(:once)
      .and_return(build)

    expect(build).to receive(:repo_source?).and_return(true)
    expect(build).to receive(:status)
      .at_least(:once)
      .and_return("SUCCESS")
    expect(build).to receive(:repo_name)
      .at_least(:once)
      .and_return("github_anipos_sparrow")
    log_url = "http://..."
    expect(build).to receive(:log_url).and_return(log_url)
    commit_sha = "58185385207383992f0f813c6014eeaf8c081809"
    expect(build).to receive(:commit_sha).and_return(commit_sha)
    expect(build).to receive(:tags).and_return(%w[tag1 tag2])

    slack_webhook = "http://slack.com/..."
    expect(ENV)
      .to receive(:[]).with("SPARROW_SLACK_WEBHOOK").and_return(slack_webhook)

    expect(slack).to receive(:faraday).and_return(faraday)

    body = {
      "blocks": [
        {
          "type": "header",
          "text": {
            "type": "plain_text",
            "text": "Build SUCCESS"
          }
        },
        {
          "type": "section",
          "fields": [
            {
              "type": "mrkdwn",
              "text": "*Repository:*\nanipos/sparrow"
            },
            {
              "type": "mrkdwn",
              "text": "*Tags:*\ntag1, tag2"
            },
            {
              "type": "mrkdwn",
              "text": "<#{slack_user_id}>"
            },
          ]
        },
        {
          "type": "actions",
          "elements": [
            {
              "type": "button",
              "text": {
                "type": "plain_text",
                "text": "View build"
              },
              "url": log_url,
              "style": "primary"
            },
            {
              "type": "button",
              "text": {
                "type": "plain_text",
                "text": "View commit"
              },
              "url": "https://github.com/anipos/sparrow/commit/#{commit_sha}",
              "style": "primary"
            },
          ]
        },
      ]
    }.to_json
    headers = { "Content-Type": "application/json" }
    expect(faraday).to receive(:post).with(slack_webhook, body, headers)

    slack.run(message)
  end

  it "#run skips if build is not repo source" do
    slack = described_class.new

    expect(message).to receive(:data).and_return("{}")
    expect(build).to receive(:repo_source?).and_return(false)
    expect(slack).to receive(:build).and_return(build)
    expect(slack).not_to receive(:faraday)

    slack.run(message)
  end

  it "#run skips if status does not match" do
    slack = described_class.new("only" => %w[SUCCESS FAILURE])

    expect(message).to receive(:data).and_return("{}")
    expect(build).to receive(:repo_source?).and_return(true)
    expect(build).to receive(:status).and_return("WORKING")
    expect(slack).to receive(:build).at_least(:once).and_return(build)
    expect(slack).not_to receive(:faraday)

    slack.run(message)
  end
end
