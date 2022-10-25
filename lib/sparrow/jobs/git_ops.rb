# frozen_string_literal: true

require "yaml"

require "sparrow/jobs/base"
require "sparrow/jobs/git_ops/rewrite"

module Sparrow
  module Jobs
    # Updates image tags of kubernetes manifest files to provide GitOps (
    # https://www.weave.works/technologies/gitops/) style operation. It
    #
    #   1. Evaluates the given ERB file.
    #   2. Writes the result to the given output file.
    #   3. Commits the output file.
    #   4. Creates a pull request.
    #
    # It requires the following environment variables.
    #   - GITHUB_TOKEN: github personal access token ("repo" scope)
    class GitOps < Base
      private

      def _run
        unless should_handle?
          Sparrow.logger.info("build is not repos source nor master, skipping", build:)
          return
        end

        rewrites.each(&:run)
      end

      # TODO(shouichi): Currently master branch only. Make it configurable.
      def should_handle?
        build.repo_source? && build.master_branch? && build.success?
      end

      def rewrites
        @rewrites ||= @args["targets"].reduce([]) do |rewrites, target|
          rewrites.push(*build_rewrites(target))
        end
      end

      def build_rewrites(target)
        target["rewrites"].map do |rewrite|
          Rewrite.new(
            build:,
            name: rewrite["name"],
            source_repo: target["source_repo"],
            config_repo: target["config_repo"],
            erb_path: rewrite["erb_path"],
            out_path: rewrite["out_path"]
          )
        end
      end
    end
  end
end
