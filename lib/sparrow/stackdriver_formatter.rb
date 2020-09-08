# frozen_string_literal: true

module Sparrow
  # @private
  class StackdriverFormatter < Ougai::Formatters::Bunyan
    def _call(severity, time, progname, data)
      if data.is_a?(Hash)
        data[:message] = data.delete(:msg)
        data[:severity] = severity
        data[:eventTime] = time
        super(severity, time, progname, data)
      else
        super(severity, time, progname, { message: data.to_s })
      end
    end
  end
end
