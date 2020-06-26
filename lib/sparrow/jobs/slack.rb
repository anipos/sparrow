# frozen_string_literal: true

require "faraday"

require "sparrow/jobs/base"

module Sparrow
  module Jobs
    # Notifies builds to slack.
    class Slack < Base
      STATUS_QUEUE = "QUEUED"
      STATUS_WORKING = "WORKING"
      STATUS_SUCCESS = "SUCCESS"
      STATUS_FAILURE = "FAILURE"

      private

      def _run
        unless should_handle?
          Sparrow.logger.info("skipping")
          return
        end

        faraday.post(url, body, headers)
        Sparrow.logger.info("sent to slack")
      end

      def should_handle?
        build.repo_source? && status_matches?
      end

      def status_matches?
        target_statuses.include?(build.status)
      end

      def target_statuses
        @args["only"] ||
          [STATUS_QUEUE, STATUS_WORKING, STATUS_SUCCESS, STATUS_FAILURE]
      end

      def url
        ENV["SPARROW_SLACK_WEBHOOK"]
      end

      def body
        # https://api.slack.com/docs/messages/builder
        {
          text: text,
          attachments: attachments
        }.to_json
      end

      def attachments
        [{
          color: color,
          fields: fields,
          actions: actions
        }]
      end

      def text
        txt = "Build #{build.status}"

        user_or_group = mention[build.status]
        return txt unless user_or_group

        # To mention user or group, the format must be like
        #   - user: @U024BE7LH
        #   - group: !subteam^SAZ94GDB8
        # See https://api.slack.com/reference/surfaces/formatting
        "#{txt} <#{user_or_group}>"
      end

      def mention
        @args["mention"] || {}
      end

      COLORS = {
        STATUS_QUEUE => "good",
        STATUS_WORKING => "good",
        STATUS_SUCCESS => "good",
        STATUS_FAILURE => "danger"
      }.freeze

      def color
        COLORS[build.status]
      end

      def fields
        [{
          title: "Repository",
          value: github_repo,
          short: true
        }, {
          title: "Tags",
          value: build.tags.join(", "),
          short: true
        }]
      end

      def actions
        [view_build_button, view_commit_button]
      end

      def view_build_button
        {
          "type": "button",
          "text": "View Build",
          "url": build.log_url
        }
      end

      def view_commit_button
        {
          "type": "button",
          "text": "View Commit",
          "url": commit_url
        }
      end

      def commit_url
        "https://github.com/#{github_repo}/commit/#{build.commit_sha}"
      end

      # TODO(shouichi): Handle other git providers (e.g., bitbucket).
      def github_repo
        build.repo_name.delete_prefix("github_").tr("_", "/")
      end

      def headers
        { "Content-Type": "application/json" }
      end

      # Visible for testing.
      def faraday
        Faraday
      end
    end
  end
end
