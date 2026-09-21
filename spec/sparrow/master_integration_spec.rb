# frozen_string_literal: true

RSpec.describe Sparrow::Master do
  let(:project_id) { "project_id_#{SecureRandom.hex}" }
  let(:subscriptions) { %w[first second].to_h { [_1, "#{_1}_#{SecureRandom.hex}"] } }
  let(:client) { Sparrow::PubSubGateway::Client.new(project_id) }
  let(:build_json) { fixture("builds", "status", "success", "github_app.json") }

  let(:config) do
    {
      "jobs" => subscriptions.map do |name, subscription|
        {
          "class" => "Recorder",
          "project_id" => project_id,
          "subscription" => subscription,
          "class_args" => { "name" => name }
        }
      end
    }
  end

  it "delivers a build to every job and stops on demand" do
    received = Queue.new
    recorder = Class.new(Sparrow::Jobs::Base) do
      define_method(:_run) { received << [@args["name"], build.status] }
    end
    stub_const("Sparrow::Jobs::Recorder", recorder)

    # Messages published to an existing subscription are kept until pulled.
    subscriptions.each_value { client.subscriber("cloud-builds", _1) }

    master = described_class.new(config)
    thread = Thread.new { master.start }
    client.publisher("cloud-builds").publish(build_json)

    results = Array.new(2) { received.pop(timeout: 10) }
    expect(results).to contain_exactly(%w[first SUCCESS], %w[second SUCCESS])

    master.stop
    expect(thread.join(10)).not_to be_nil
  end
end
