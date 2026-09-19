# frozen_string_literal: true

require "faraday"

require "sparrow/jobs/base"

module Sparrow
  module Jobs
    # Notifies builds to slack.
    class Slack < Base # rubocop:disable Metrics/ClassLength
      HEADERS = { "Content-Type": "application/json" }.freeze

      private

      def _run
        unless should_handle?
          Sparrow.logger.info("skipping")
          return
        end

        faraday.post(url, body, HEADERS)
        Sparrow.logger.info("sent to slack")
      end

      def should_handle?
        build.repo_source? && status_matches?
      end

      def status_matches?
        target_statuses.intersect?(status_keys)
      end

      # FAILURE in the config also covers the other failed statuses.
      def status_keys
        build.failed? ? [build.status, "FAILURE"].uniq : [build.status]
      end

      def target_statuses
        @args["only"] || %w[QUEUED WORKING SUCCESS FAILURE]
      end

      def url
        ENV.fetch("SPARROW_SLACK_WEBHOOK", nil)
      end

      def body
        # https://api.slack.com/block-kit/building
        { blocks: }.to_json
      end

      def blocks
        [heading, main, actions]
      end

      def heading
        {
          type: "header",
          text: {
            type: "plain_text",
            text: "Build #{build.status}"
          }
        }
      end

      def main
        fields = main_fields_info
        mention = main_fields_mention
        fields << mention if mention

        {
          type: "section",
          fields:
        }
      end

      def main_fields_info
        [{
          type: "mrkdwn",
          text: "*Repository:*\n#{build.github_repo || build.repo_name}"
        }, {
          type: "mrkdwn",
          text: "*Tags:*\n#{build.tags.join(', ')}"
        }]
      end

      def main_fields_mention
        # To mention user or group, the format must be like
        #   - user: @U024BE7LH
        #   - group: !subteam^SAZ94GDB8
        # See https://api.slack.com/reference/surfaces/formatting
        user_or_group = status_keys.filter_map { mention_on_status[_1] }.first
        return unless user_or_group

        {
          type: "mrkdwn",
          text: "<#{user_or_group}>"
        }
      end

      def mention_on_status
        @args["mention"] || {}
      end

      def actions
        {
          type: "actions",
          elements: [view_build_button, view_commit_button].compact
        }
      end

      def view_build_button
        {
          type: "button",
          text: {
            type: "plain_text",
            text: "View build"
          },
          url: build.log_url,
          style:
        }.compact
      end

      def view_commit_button
        return unless build.github_repo && build.commit_sha

        {
          type: "button",
          text: {
            type: "plain_text",
            text: "View commit"
          },
          url: "https://github.com/#{build.github_repo}/commit/#{build.commit_sha}",
          style:
        }.compact
      end

      def style
        return "primary" if build.success?

        "danger" if build.failed?
      end

      # Visible for testing.
      def faraday
        Faraday
      end
    end
  end
end
