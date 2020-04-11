# frozen_string_literal: true

require "sparrow/pub_sub_gateway"
require "sparrow/worker"

module Sparrow
  # Master is the master process that starts workers.
  class Master
    def initialize(config)
      @config = config
    end

    # Starts workers and blocks for them to exit.
    def start
      workers.map(&:start).map(&:wait!)
    end

    private

    def workers
      @workers ||= @config["jobs"].reduce([]) do |workers, spec|
        workers << build_worker(spec)
      end
    end

    def build_worker(spec)
      project_id = spec["project_id"]
      # Sparrow only handles messages from cloud builds.
      topic = "cloud-builds"
      subscription = spec["subscription"]
      gateway = PubSubGateway.new(project_id, topic, subscription)
      job_class = Object.const_get("Sparrow::Jobs::#{spec['class']}")
      Worker.new(gateway, job_class, spec["class_args"])
    end
  end
end
