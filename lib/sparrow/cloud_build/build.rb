# frozen_string_literal: true

module Sparrow
  module CloudBuild
    # A message in the cloud build pubsub topic ("cloud-builds").
    # https://cloud.google.com/cloud-build/docs/api/reference/rest/v1/projects.builds
    class Build
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

      def log_url
        data["logUrl"]
      end

      def tags
        data["tags"] || []
      end

      def repo_source?
        # source.repoSource is empty for new github connection method, but is not for legacy method.
        # substitutions.REPO_NAME is empty for legacy method, but is not for new method.
        !source["repoSource"].nil? || !repo_name.nil?
      end

      def to_json(*args)
        data.to_json(*args)
      end

      private

      def source
        data["source"] || {}
      end

      def substitutions
        data["substitutions"] || {}
      end
    end
  end
end
