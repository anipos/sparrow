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
        repo_source["branchName"]
      end

      def repo_name
        repo_source["repoName"]
      end

      def commit_sha
        data["sourceProvenance"]["resolvedRepoSource"]["commitSha"]
      end

      def log_url
        data["logUrl"]
      end

      def tags
        data["tags"] || []
      end

      def repo_source?
        !source["repoSource"].nil?
      end

      private

      def repo_source
        source["repoSource"] || {}
      end

      def source
        data["source"] || {}
      end
    end
  end
end
