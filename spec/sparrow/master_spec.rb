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

    subscription = instance_double("subscription")
    expect(subscription).to receive(:wait!).twice

    worker = instance_double("worker")
    expect(worker).to receive(:start)
      .twice
      .and_return(subscription)

    expect(Sparrow::Worker).to receive(:new)
      .twice
      .with(anything, Sparrow::Jobs::Print, { "key" => "val" })
      .and_return(worker)

    expect { master.start }.not_to raise_error
  end
end
