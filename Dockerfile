# Base image
FROM ruby:3.4.4 as base

ENV LANG C.UTF-8

ENV APP_ROOT /sparrow

ENV SPARROW_VERSION 0.1.0

WORKDIR $APP_ROOT

# Build image
FROM base as builder

COPY Gemfile Gemfile.lock sparrow.gemspec $APP_ROOT/
COPY lib/sparrow/version.rb $APP_ROOT/lib/sparrow/version.rb
RUN bundle install

COPY . $APP_ROOT

RUN rake build

# Final image
FROM base

COPY --from=builder $APP_ROOT/pkg/sparrow-$SPARROW_VERSION.gem .
RUN gem install sparrow-$SPARROW_VERSION.gem

# To tell sentry the sparrow version.
# https://docs.sentry.io/platforms/ruby/configuration/options/
RUN echo $SPARROW_VERSION > REVISION

RUN useradd sparrow
USER sparrow:sparrow

ENTRYPOINT ["sparrow"]
