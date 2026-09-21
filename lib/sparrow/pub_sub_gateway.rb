# frozen_string_literal: true

require "faraday"
require "google/cloud/pubsub"
require "octokit"
require "sentry-ruby"

module Sparrow
  # A Cloud PubSub abstraction. It calls a worker on message arrival.
  #
  # Requires the following permissions.
  #   - roles/pubsub.subscriber
  #   - roles/pubsub.viewer
  class PubSubGateway
    RETRYABLE_ERRORS = [
      Faraday::ConnectionFailed,
      Faraday::ServerError,
      Octokit::ServerError,
      Octokit::TooManyRequests,
    ].freeze

    def initialize(project_id, topic_name, subscription_name)
      @project_id = project_id
      @topic_name = topic_name
      @subscription_name = subscription_name
    end

    # Starts receiving messages from the pubsub topic. It calls
    # `worker.process_message` on message arrival. It does not block; to wait
    # this call to exit, call `wait!`.
    def subscribe(worker)
      listener = listen(worker)
      listener.on_error { |e| on_error(e) }
      listener.start
    end

    private

    def logger
      @logger ||= Sparrow.logger.child(
        topic_name: @topic_name,
        subscription_name: @subscription_name
      )
    end

    def on_error(error)
      logger.error(error)
    end

    def client
      @client ||= Client.new(@project_id)
    end

    def subscriber
      @subscriber ||= client.subscriber(@topic_name, @subscription_name)
    end

    def listen(worker)
      subscriber.listen do |message|
        worker.process_message(message)
        message.acknowledge!
      rescue StandardError => e
        logger.error("job failed", e, message: message.data, retry: retryable?(e))
        Sentry.capture_exception(e) { |scope| scope.set_extras(message: message.data) }
        retryable?(e) ? message.reject! : message.acknowledge!
      end
    end

    def retryable?(error)
      RETRYABLE_ERRORS.any? { error.is_a?(_1) }
    end

    # The emulator aware pubsub client.
    class Client
      def initialize(project_id)
        @project_id = project_id
      end

      # Returns the publisher. Creates the topic iff the emulator is used
      # before return.
      def publisher(topic_name)
        pubsub.publisher(topic_name)
      rescue Google::Cloud::NotFoundError
        create_topic(topic_name)
        pubsub.publisher(topic_name)
      end

      # Returns the subscriber. Creates the subscription iff the emulator is
      # used before return.
      def subscriber(topic_name, subscription_name)
        pubsub.subscriber(subscription_name)
      rescue Google::Cloud::NotFoundError
        create_subscription(topic_name, subscription_name)
        pubsub.subscriber(subscription_name)
      end

      private

      def pubsub
        @pubsub ||= Google::Cloud::PubSub.new(project_id: @project_id)
      end

      def emulator?
        ENV.fetch("PUBSUB_EMULATOR_HOST", false)
      end

      def create_topic(name)
        raise Sparrow::Error, "create topic iff emulator" unless emulator?

        pubsub.topic_admin.create_topic(name: pubsub.topic_path(name))
      end

      def create_subscription(topic_name, subscription_name)
        raise Sparrow::Error, "create subscription iff emulator" unless emulator?

        publisher(topic_name)
        pubsub.subscription_admin.create_subscription(
          name: pubsub.subscription_path(subscription_name),
          topic: pubsub.topic_path(topic_name)
        )
      end
    end
  end
end
