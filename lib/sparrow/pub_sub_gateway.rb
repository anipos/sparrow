# frozen_string_literal: true

require "google/cloud/pubsub"
require "sentry-ruby"

module Sparrow
  # A Cloud PubSub abstraction. It calls a worker on message arrival.
  #
  # Requires the following permissions.
  #   - roles/pubsub.subscriber
  #   - roles/pubsub.viewer
  class PubSubGateway
    def initialize(project_id, topic_name, subscription_name)
      @project_id = project_id
      @topic_name = topic_name
      @subscription_name = subscription_name
    end

    # Starts receiving messages from the pubsub topic. It calls
    # `worker.process_message` on message arrival. It does not block; to wait
    # this call to exit, call `wait!`.
    def subscribe(worker)
      subscriber = listen(worker)
      subscriber.on_error { |e| on_error(e) }
      subscriber.start
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

    def subscription
      @subscription ||= client.subscription(@topic_name, @subscription_name)
    end

    def listen(worker)
      subscription.listen do |message|
        worker.process_message(message)
        message.acknowledge!
      rescue StandardError => e
        Sentry.with_scope do |scope|
          scope.set_extras(message: message.data)
          Sentry.capture_exception(e)
        end
      end
    end

    # The emulator aware pubsub client.
    class Client
      def initialize(project_id)
        @project_id = project_id
      end

      # Returns the topic. Creates one iff the emulator is used before return.
      def topic(name)
        pubsub.topic(name) || create_topic(name)
      end

      # Returns the subscription. Creates one iff the emulator is used before
      # return.
      def subscription(topic_name, subscription_name)
        pubsub.subscription(subscription_name) ||
          create_subscription(topic_name, subscription_name)
      end

      private

      def pubsub
        @pubsub ||= Google::Cloud::PubSub.new(project_id: @project_id)
      end

      def emulator?
        return false if env_present?("GOOGLE_APPLICATION_CREDENTIALS")

        env_present?("PUBSUB_EMULATOR_HOST")
      end

      def create_topic(name)
        raise Sparrow::Error, "create topic iff emulator" unless emulator?

        pubsub.create_topic(name)
      end

      def create_subscription(topic_name, subscription_name)
        raise Sparrow::Error, "create subscription iff emulator" unless emulator?

        topic = topic(topic_name)
        topic.subscribe(subscription_name)
      end

      def env_present?(key)
        !(ENV[key] || "").empty?
      end
    end
  end
end
