# frozen_string_literal: true

module Sparrow
  module Jobs
    # @private
    class Base
      attr_reader :build

      def initialize(args = {})
        @args = args
      end

      def run(message)
        @build = Sparrow::CloudBuild::Build.new(JSON.parse(message.data))
        _run
      end

      private

      # Child class must override this method.
      def _run
        raise Sparrow::Error, "#_run is not implemented"
      end
    end
  end
end
