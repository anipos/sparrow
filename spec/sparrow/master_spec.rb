# frozen_string_literal: true

RSpec.describe Sparrow::Master do
  subject(:master) { described_class.new }

  it "#start does not raise an error" do
    yaml = <<~YAML
      jobs:
        - class: Print
          project_id: whatever
          subscription: print1
          class_args:
            key: val

        - class: Print
          project_id: whatever
          subscription: print2
          class_args:
            key: val
    YAML

    config = YAML.safe_load(yaml)
    master = described_class.new(config)

    calls = []

    subscription = instance_double("subscription")
    expect(subscription).to receive(:stop).twice do
      calls << :stop
    end
    expect(subscription).to receive(:wait!).twice do
      calls << :wait!
    end

    worker = instance_double("worker")
    expect(worker).to receive(:start).twice do
      calls << :start
      subscription
    end

    expect(Sparrow::Worker).to receive(:new)
      .twice
      .with(anything, Sparrow::Jobs::Print, { "key" => "val" })
      .and_return(worker)

    master.stop
    expect { master.start }.not_to raise_error
    expect(calls).to eq(%i[start start stop stop wait! wait!])
  end
end
