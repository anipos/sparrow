# Sparrow

![monorail](docs/assets/mascot.png)

Sparrow is a bot runs jobs on Cloud Build events. It subscribes to Cloud Build
events through the Cloud PubSub topic `cloud-builds`, which is available out of
the box.

Sparrow can

- send messages to slack
- rewrite container image tags in Kubernetes manifest files

Sparrow might be helpful if you

- follow Trunk Based Development https://trunkbaseddevelopment.com/
- follow GitOps https://www.weave.works/technologies/gitops/

Sparrow is an alpha project and is subject to change (though it works well on
our specific use case).

## Features

### Send Messages to Slack

Sparrow sends messages to Slack on every Cloud Build event. A slack message
has links to

- Cloud Build page of the build
- GitHub page of the commit

We plan to support

- filtering (e.g., only failed builds)
- mention
- sending messages to different channels (based on rules)

### Rewrite Container Image Tags in Kubernetes Manifests

Sparrow rewrites container image tags in Kubernetes manifest files by creating
pull requests on GitHub.

Sparrow assumes an app

- to have code repository and source repository
- to build container images on every push to the master branch

When a commit is pushed to the code repository's master branch,

1. Cloud Build builds a container image where its tag is git SHA.
1. The event is published to Cloud PubSub.
1. Sparrow creates a tag rewrite pull request to the config repository.

A commit message of tag rewriting contains

- the commit message from the source repository's commit
- the link the source repository's commit on GitHub

Sparrow has many assumptions for tag rewriting to work. We don't have a plan
to support other use cases (code and config repositories are the same for
example) but contributions are welcome.

## Configuration

The behavior of Sparrow is configured by `SPARROW_CONFIG` that points to a path
of a YAML file. For example `SPARROW_CONFIG=/etc/sparrow.yml`.

### Configuration YAML Specification

The sparrow configuration YAML supports the following keys.

```
# Configuration spec version, currently 0.1.
version: 0.1

# `jobs` specifies what jobs to run from Cloud PubSub subscription X of project
# Y.
jobs:
  # Run `Slack` job on events streamed from `project-a`'s Cloud PubSub
  # subscription `slack`. `Slack` job sends messages to slack on every event.
  - class: Slack
    project_id: project-a
    subscription: slack

  # Run `GitOps` job on events streamed from `project-b`'s Cloud PubSub
  # subscription `gitops`. `GitOps` updates container image tags on kubernetes
  # manifest files.
  - class: GitOps
    project_id: project-b
    subscription: gitops
    class_args:
      targets:
        # When an event is from repository "org/app1", evaluates the ERB
        # template at `overlays/dev/kustomization.yaml.erb` in the
        # configuration repository `org/app1-conf` and writes the evaluated
        # result to `overlays/dev/kustomization.yaml`.
        - source_repo: org/app1
          config_repo: org/app1-conf
          rewrites:
            - name: dev
              erb_path: overlays/dev/kustomization.yaml.erb
              out_path: overlays/dev/kustomization.yaml
```

## Deployment

You can deploy Sparrow using Docker. Docker image is available at
https://hub.docker.com/r/anipos/sparrow.

Sparrow requires

- `SPARROW_CONFIG`: The path to the sparrow.yml.
- `SPARROW_SLACK_WEBHOOK`: Slack webhook URL.
- `GOOGLE_APPLICATION_CREDENTIALS`: Google Cloud IAM key.
- `GITHUB_TOKEN`: GitHub personal access token with "repo" scope.

The IAM key must have

- roles/pubsub.subscriber
- roles/pubsub.viewer

## Development

TBA.
