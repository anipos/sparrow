# frozen_string_literal: true

require "sparrow/jobs/base"

module Sparrow
  module Jobs
    # Prints builds.
    class Print < Base
      private

      # Prints the build to the logger.
      def _run
        Sparrow.logger.info("received a build", build: build.data)
      end
    end
  end
end
