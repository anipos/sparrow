# frozen_string_literal: true

RSpec.describe Sparrow::Jobs::GitOps::Rewrite do
  let(:build) { instance_double("build") }
  let(:octokit) { instance_double("octokit") }
  let(:master_branch) { instance_double("master_branch") }
  let(:master_commit) { instance_double("master_commit") }
  let(:source_commit) { instance_double("source_commit") }
  let(:source_commit_commit) { instance_double("source_commit_commit") }
  let(:blob) { instance_double("blob") }
  let(:content) { instance_double("content") }
  let(:ref) { instance_double("ref") }
  let(:branch) { instance_double("branch") }
  let(:new_commit) { instance_double("new_commit") }

  let(:source_sha) { "24744b98e414d74ead1d26aa0e297e8a06737703" }
  let(:master_sha) { "8d296129458e118fe131eebc8012403234fdc47f" }
  let(:tree_sha) { "6e5a7dc2accf70e46eb93e478deb8a6e8c57c3bc" }
  let(:new_commit_sha) { "48abac143f1c548172888918c6a56e40cacd010a" }
  let(:erb) { Base64.encode64("erb") }

  let(:name) { "test-rewrite" }
  let(:source_repo) { "anipos/sparrow" }
  let(:config_repo) { "anipos/sparrow-conf" }
  let(:erb_path) { "base/deploy.yaml.erb" }
  let(:out_path) { "base/deploy.yaml" }

  let(:rewrite) do
    described_class.new(
      build: build,
      name: name,
      source_repo: source_repo,
      config_repo: config_repo,
      erb_path: erb_path,
      out_path: out_path
    )
  end

  it "#run does not raise an error" do
    expect(build).to receive(:repo_name).and_return("github_anipos_sparrow")
    expect(build).to receive(:master_branch?).and_return(true)
    expect(build).to receive(:commit_sha)
      .at_least(:once)
      .and_return(source_sha)

    # Octokit::Client.new
    expect(ENV).to receive(:[]).with("GITHUB_TOKEN").and_return("token")
    expect(Octokit::Client).to receive(:new)
      .with(access_token: "token").and_return(octokit)

    # octokit.branch(repo, "master").commit.sha
    expect(octokit).to receive(:branch)
      .with(config_repo, "master")
      .and_return(master_branch)
    expect(master_branch).to receive(:commit)
      .at_least(:once)
      .and_return(master_commit)
    expect(master_commit).to receive(:sha)
      .at_least(:once)
      .and_return(master_sha)

    # octokit.content(erb_path).content
    expect(octokit).to receive(:content)
      .and_return(content)
      .with(config_repo, path: erb_path, ref: master_sha)
    expect(content).to receive(:content).and_return(erb)

    # octokit.create_blob
    expect(octokit).to receive(:create_blob).and_return(blob)

    # octokit.create_ref
    expect(octokit).to receive(:create_tree)
      .with(
        config_repo,
        [{ path: out_path, sha: blob, mode: "100644", type: "blob" }],
        base_tree: master_sha
      ).and_return(ref)
    expect(ref).to receive(:sha).and_return(tree_sha)

    # octokit.create_commit
    title = "Update tag to #{source_sha}"
    body = <<~MSG
      > Title
      >
      > Body

      https://github.com/#{source_repo}/commit/#{source_sha}
    MSG
    commit_message = <<~MSG
      #{title}

      #{body}
    MSG
    expect(source_commit_commit).to receive(:message)
      .at_least(:once)
      .and_return("Title\n\nBody")
    expect(source_commit).to receive(:commit)
      .at_least(:once)
      .and_return(source_commit_commit)
    expect(octokit).to receive(:commit)
      .with(source_repo, build.commit_sha)
      .and_return(source_commit)
    expect(octokit).to receive(:create_commit)
      .with(config_repo, commit_message, tree_sha, master_sha)
      .and_return(new_commit)

    # octokit.create_ref
    expect(new_commit).to receive(:sha).and_return(new_commit_sha)
    branch_name = "heads/gitops-#{source_sha}-#{name}"
    expect(octokit).to receive(:create_ref)
      .with(config_repo, branch_name, new_commit_sha)
      .and_return(branch)

    # octokit.create_pull_request
    expect(branch).to receive(:ref).and_return("branch_name")
    expect(octokit).to receive(:create_pull_request)
      .with(config_repo, "master", "branch_name", title, body)

    rewrite.run
  end
end
