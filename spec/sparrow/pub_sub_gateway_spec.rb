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

  it "#subscribe" do
    subscriber = gateway.subscribe(worker)

    expect(worker).to receive(:process_message)
    topic = pubsub.topic(topic_name)
    topic.publish("hello")

    # No proper way to wait for the message to arrive.
    sleep 1
    subscriber.stop.wait!
  end
end
