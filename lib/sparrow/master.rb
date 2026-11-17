# frozen_string_literal: true

require "sparrow/pub_sub_gateway"
require "sparrow/worker"

module Sparrow
  # Master is the master process that starts workers.
  class Master
    def initialize(config)
      @config = config
      @stop = Queue.new
    end

    # Starts all workers and then blocks until `stop` is called and in-flight
    # jobs finish.
    def start
      subscribers = workers.map(&:start)
      @stop.pop
      Sparrow.logger.info("stopping workers")
      subscribers.each(&:stop)
      # `wait!` before `stop` returns immediately and shuts down the callback
      # pool since google-cloud-pubsub 3.5.0.
      subscribers.each(&:wait!)
    end

    # Unblocks `start`. Safe to call from any thread.
    def stop
      @stop << true
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
