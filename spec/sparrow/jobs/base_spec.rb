# frozen_string_literal: true

RSpec.describe Sparrow::Jobs::Base do
  let(:message) { instance_double("message") }

  it "#run raises an error" do
    expect(message).to receive(:data).and_return("{}")

    expect { described_class.new.run(message) }.to raise_error(Sparrow::Error)
  end
end
