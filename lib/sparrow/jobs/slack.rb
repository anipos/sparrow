# frozen_string_literal: true

require "faraday"

require "sparrow/jobs/base"

module Sparrow
  module Jobs
    # Notifies builds to slack.
    #
    # TODO(shouichi): Provide filtering (e.g., only failed builds).
    # TODO(shouichi): Provide mention (e.g., @team-a on failure).
    class Slack < Base
      private

      def _run
        unless should_handle?
          Sparrow.logger.info("build is not repos source, skipping")
          return
        end

        faraday.post(url, body, headers)
        Sparrow.logger.info("sent to slack")
      end

      def should_handle?
        build.repo_source?
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
        "Build #{build.status}"
      end

      COLORS = {
        "QUEUED" => "good",
        "WORKING" => "good",
        "SUCCESS" => "good",
        "FAILURE" => "danger"
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
