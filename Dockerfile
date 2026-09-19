# Base image
FROM ruby:4.0.7-slim AS base

ENV LANG=C.UTF-8
ENV APP_ROOT=/sparrow
ENV SPARROW_VERSION=0.1.0
# Runtime gems only; the lockfile is the single source of truth.
ENV BUNDLE_WITHOUT=development:test
ENV BUNDLE_FROZEN=1

WORKDIR $APP_ROOT

# Build image
FROM base AS builder

# Compiler for gems with C extensions (oj, bigdecimal, json).
RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential \
  && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock sparrow.gemspec $APP_ROOT/
COPY lib/sparrow/version.rb $APP_ROOT/lib/sparrow/version.rb
RUN bundle install

COPY . $APP_ROOT

RUN gem build sparrow.gemspec

# Final image
FROM base

# Dependencies are already installed by the builder. Installing the gem with
# --local only registers it and avoids fetching anything from rubygems.org.
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder $APP_ROOT/sparrow-$SPARROW_VERSION.gem .
RUN gem install --local --no-document sparrow-$SPARROW_VERSION.gem \
  && rm sparrow-$SPARROW_VERSION.gem

# To tell sentry the sparrow version.
# https://docs.sentry.io/platforms/ruby/configuration/options/
RUN echo $SPARROW_VERSION > REVISION

RUN useradd sparrow
USER sparrow:sparrow

ENTRYPOINT ["sparrow"]
