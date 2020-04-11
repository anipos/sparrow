# frozen_string_literal: true

RSpec.describe Sparrow::Jobs::GitOps do
  let(:message) { instance_double("message") }
  let(:build) { instance_double("build") }
  let(:rewrite) { instance_double("rewrite") }

  it "#run does not raise an error" do
    yaml = <<~YAML
      targets:
        - source_repo: anipos/sparrow
          config_repo: anipos/sparrow-conf
          rewrites:
            - name: base
              erb_path: base/deploy.yaml.erb
              out_path: base/deploy.yaml
    YAML
    args = YAML.safe_load(yaml)
    gitops = described_class.new(args)

    expect(message).to receive(:data).and_return("{}")

    allow(gitops).to receive(:build).and_return(build)

    expect(build).to receive(:repo_source?).and_return(true)
    expect(build).to receive(:master_branch?).and_return(true)
    expect(build).to receive(:success?).and_return(true)

    allow(gitops).to receive(:content).and_return(yaml)

    allow(Sparrow::Jobs::GitOps::Rewrite).to receive(:new).and_return(rewrite)

    expect(rewrite).to receive(:run)

    gitops.run(message)
  end

  it "#run skips if build does not match" do
    gitops = described_class.new
    expect(message).to receive(:data).and_return("{}")
    allow(gitops).to receive(:build).and_return(build)

    expect(build).to receive(:repo_source?).and_return(false)
    expect(gitops).not_to receive(:rewrites)

    gitops.run(message)
  end
end
