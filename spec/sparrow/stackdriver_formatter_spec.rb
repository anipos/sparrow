# frozen_string_literal: true

RSpec.describe Sparrow::StackdriverFormatter do
  it "outputs logs in stackdriver format to stdout" do
    out = StringIO.new
    logger = Ougai::Logger.new(out)
    logger.formatter = described_class.new

    logger.info("hello")

    json = JSON.parse(out.string)
    expect(json).to include("message")
    expect(json).to include("severity")
    expect(json).to include("eventTime")
  end
end
