# frozen_string_literal: true

module Sparrow
  module CloudBuild
    # A message in the cloud build pubsub topic ("cloud-builds").
    # https://cloud.google.com/cloud-build/docs/api/reference/rest/v1/projects.builds
    class Build
      FAILED_STATUSES = %w[FAILURE INTERNAL_ERROR TIMEOUT EXPIRED].freeze

      attr_reader :data

      def initialize(data)
        @data = data
      end

      def master_branch?
        branch == "master"
      end

      def success?
        status == "SUCCESS"
      end

      def failed?
        FAILED_STATUSES.include?(status)
      end

      def status
        data["status"]
      end

      def branch
        substitutions["BRANCH_NAME"]
      end

      def repo_name
        substitutions["REPO_NAME"]
      end

      def commit_sha
        substitutions["COMMIT_SHA"]
      end

      def github_repo
        substitutions["REPO_FULL_NAME"]
      end

      def log_url
        data["logUrl"]
      end

      def tags
        data["tags"] || []
      end

      def repo_source?
        !repo_name.nil?
      end

      def to_json(*)
        data.to_json(*)
      end

      private

      def substitutions
        data["substitutions"] || {}
      end
    end
  end
end
