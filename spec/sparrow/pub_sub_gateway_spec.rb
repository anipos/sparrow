# frozen_string_literal: true

RSpec.describe Sparrow::PubSubGateway do
  subject(:gateway) do
    described_class.new(project_id, topic_name, subscription_name)
  end

  let(:project_id) { "project_id_#{SecureRandom.hex}" }
  let(:topic_name) { "topic_name_#{SecureRandom.hex}" }
  let(:subscription_name) { "subscription_name_#{SecureRandom.hex}" }
  let(:worker) { instance_double("fake_worker") }
  let(:pubsub) { Sparrow::PubSubGateway::Client.new(project_id) }

  it "calls Worker#process_message" do
    subscriber = gateway.subscribe(worker)

    expect(worker).to receive(:process_message)
    topic = pubsub.topic(topic_name)
    topic.publish("hello")

    # No proper way to wait for the message to arrive.
    sleep 1
    subscriber.stop.wait!
  end

  it "Sentry.capture_exception on worker exception" do
    subscriber = gateway.subscribe(worker)

    # https://github.com/getsentry/sentry-ruby/blob/fddb235b0b21cf78cd0d9f37e1fa2ab60febbf4c/sentry-ruby/spec/spec_helper.rb#L82
    Sentry.init do |config|
      config.breadcrumbs_logger = [:sentry_logger]
      config.dsn = "http://12345:67890@sentry.localdomain/sentry/42"
      config.transport.transport_class = Sentry::DummyTransport
      config.background_worker_threads = 0
      config.traces_sample_rate = 1.0
    end

    expect(worker).to receive(:process_message).and_raise("boom")
    topic = pubsub.topic(topic_name)
    topic.publish("hello")

    # No proper way to wait for the message to arrive.
    sleep 1
    subscriber.stop.wait!
    expect(Sentry.get_current_client.transport.events.count).to eq(1)
  end
end
