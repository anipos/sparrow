# frozen_string_literal: true

RSpec.describe Sparrow::Worker do
  let(:gateway) { instance_double("fake_gateway") }
  let(:job_class) { instance_double("fake_job_class") }
  let(:job_args) { instance_double("fake_job_args") }
  let(:worker) { described_class.new(gateway, job_class, job_args) }
  let(:message) { instance_double("message") }

  it "#start calls gateway#subscribe" do
    subscriber = instance_double("fake_subscriber")
    expect(gateway).to receive(:subscribe).with(worker).and_return(subscriber)
    worker.start
  end

  it "#process_message runs a job" do
    job = instance_double("face_job")
    expect(job_class).to receive(:new).with(job_args).and_return(job)
    expect(job).to receive(:run).with(message)
    worker.process_message(message)
  end
end
