# Base image
FROM ruby:3.0.1 as base

ENV LANG C.UTF-8

ENV APP_ROOT /app

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

ENV SPARROW_VERSION 0.1.0

COPY --from=builder /app/pkg/sparrow-$SPARROW_VERSION.gem .
RUN gem install sparrow-$SPARROW_VERSION.gem

ENTRYPOINT ["sparrow"]
