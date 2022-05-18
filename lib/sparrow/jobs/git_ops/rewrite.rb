# frozen_string_literal: true

require "erb"
require "octokit"

module Sparrow
  module Jobs
    class GitOps < Base
      # @private
      # rubocop:disable Metrics/ClassLength
      class Rewrite
        # rubocop:disable Metrics/ParameterLists
        def initialize(
          build:,
          name:,
          source_repo:,
          config_repo:,
          erb_path:,
          out_path:
        )
          # rubocop:enable Metrics/ParameterLists
          @build = build
          @name = name
          @source_repo = source_repo
          @config_repo = config_repo
          @erb_path = erb_path
          @out_path = out_path
        end

        # rubocop:disable Metrics/MethodLength
        def run
          unless match?
            logger.info("build does not match, skipping")
            return
          end

          if no_changes?
            logger.info("no changes, skipping")
            return
          end

          begin
            pr = create_pull_request
            logger.info("created a pull request", pr: pr.to_h)
            pr
          rescue Octokit::UnprocessableEntity => e
            logger.info("pull request exists, skipping", error: e)
            nil
          end
        end
        # rubocop:enable Metrics/MethodLength

        private

        def logger
          @logger ||= Sparrow.logger.child(name: @name, build: @build)
        end

        # TODO(shouichi): Currently master branch only. Make it configurable.
        def match?
          source_repo_match? && @build.master_branch?
        end

        def source_repo_match?
          cloud_source_repo == @build.repo_name
        end

        # TODO(shouichi): Handle other git providers (e.g., bitbucket).
        def cloud_source_repo
          # Cloud Source Repositories downcases org/repo names (e.g., Foo/Bar
          # -> foo_bar).
          "github_#{@source_repo.tr('/', '_')}".downcase
        end

        def no_changes?
          comparision = client.compare(
            @config_repo,
            "master",
            commit.sha
          )
          comparision.files.empty?
        end

        def pull_requests
          @pull_requests ||= client.pull_requests(@config_repo)
        end

        def client
          @client ||= Octokit::Client.new(access_token: ENV.fetch("GITHUB_TOKEN", nil))
        end

        def master_branch
          @master_branch ||= client.branch(@config_repo, "master")
        end

        def blob
          client.create_blob(@config_repo, rendered_template).tap do |blob|
            logger.debug("created blob", blob: blob)
          end
        end

        # rubocop:disable Metrics/MethodLength
        def tree
          client.create_tree(
            @config_repo,
            [{
              path: @out_path,
              mode: "100644",
              type: "blob",
              sha: blob
            }],
            base_tree: master_branch.commit.sha
          ).tap do |tree|
            logger.debug("created tree", tree: tree.to_h)
          end
        end
        # rubocop:enable Metrics/MethodLength

        def commit
          @commit ||= client.create_commit(
            @config_repo,
            commit_message,
            tree.sha,
            master_branch.commit.sha
          ).tap do |commit|
            logger.debug("created commit", commit: commit.to_h)
          end
        end

        def ref
          @ref ||= client.create_ref(@config_repo, branch_name, commit.sha).tap do |ref|
            logger.debug("created ref", ref: ref.to_h)
          end
        end

        def create_pull_request
          client.create_pull_request(
            @config_repo,
            "master",
            ref.ref,
            title,
            body
          )
        end

        def branch_name
          "heads/gitops-#{@build.commit_sha}-#{sanitized_name}"
        end

        def sanitized_name
          @name.tr("/", "-")
        end

        def title
          "Update tag to #{@build.commit_sha}"
        end

        def link_to_source_commit
          "https://github.com/#{@source_repo}/commit/#{@build.commit_sha}"
        end

        def source_commit
          @source_commit ||= client.commit(@source_repo, @build.commit_sha)
        end

        def quoted_source_commit_message
          source_commit.commit.message
            .split("\n")
            .map { |l| l.empty? ? ">" : "> #{l}" }
            .join("\n")
        end

        def commit_message
          <<~MSG
            #{title}

            #{body}
          MSG
        end

        def body
          <<~MSG
            #{quoted_source_commit_message}

            #{link_to_source_commit}
          MSG
        end

        def rendered_template
          template.result_with_hash(tag: @build.commit_sha)
        end

        def template
          @template ||= ERB.new(
            Base64.decode64(
              client.content(
                @config_repo,
                path: @erb_path,
                ref: master_branch.commit.sha
              ).content
            )
          )
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
