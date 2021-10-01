# frozen_string_literal: true

module Sparrow
  # Processes jobs on the message arrival.
  class Worker
    def initialize(gateway, job_class, job_args)
      @gateway = gateway
      @job_class = job_class
      @job_args = job_args
    end

    # Starts receiving messages from the gateway. It does not block; caller is
    # responsible for calling `wait!` to block.
    def start
      Sparrow.logger.info("worker started", job: { class: @job_class, args: @job_args })
      @gateway.subscribe(self)
    end

    # Processes a job based on the message.
    def process_message(message)
      @job_class.new(@job_args).run(message)
    end
  end
end
