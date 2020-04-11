# frozen_string_literal: true

RSpec.describe Sparrow::Jobs::Print do
  let(:message) { instance_double("message") }

  it "#run does not raise an error" do
    expect(message).to receive(:data).and_return("{}")

    expect { described_class.new.run(message) }.not_to raise_error
  end
end
