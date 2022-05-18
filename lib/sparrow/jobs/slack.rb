# frozen_string_literal: true

require "faraday"

require "sparrow/jobs/base"

module Sparrow
  module Jobs
    # Notifies builds to slack.
    class Slack < Base # rubocop:disable Metrics/ClassLength
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
        target_statuses.include?(build.status)
      end

      def target_statuses
        @args["only"] || %w[QUEUED WORKING SUCCESS FAILURE]
      end

      def url
        ENV.fetch("SPARROW_SLACK_WEBHOOK", nil)
      end

      def body
        # https://api.slack.com/block-kit/building
        { blocks: blocks }.to_json
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
          fields: fields
        }
      end

      def main_fields_info
        [{
          type: "mrkdwn",
          text: "*Repository:*\n#{github_repo}"
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
        user_or_group = mention_on_status[build.status]
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
          elements: [view_build_button, view_commit_button]
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
          style: style
        }.compact
      end

      def view_commit_button
        {
          type: "button",
          text: {
            type: "plain_text",
            text: "View commit"
          },
          url: "https://github.com/#{github_repo}/commit/#{build.commit_sha}",
          style: style
        }.compact
      end

      def style
        {
          "SUCCESS" => "primary",
          "FAILURE" => "danger"
        }[build.status]
      end

      # TODO(shouichi): Handle other git providers (e.g., bitbucket).
      def github_repo
        build.repo_name.delete_prefix("github_").tr("_", "/")
      end

      # Visible for testing.
      def faraday
        Faraday
      end

      HEADERS = { "Content-Type": "application/json" }.freeze
    end
  end
end
