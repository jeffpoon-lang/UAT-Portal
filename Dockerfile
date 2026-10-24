# syntax=docker/dockerfile:1
# Production image：先 build Rust 嘅 uat-seal，再放入 Rails image。
#   docker build -t uat-portal .
#   docker run -p 3000:3000 -e RAILS_MASTER_KEY=... -e DATABASE_URL=... uat-portal

ARG RUBY_VERSION=3.3.6

# ---- 1. Rust：build uat-seal ----
FROM rust:1-slim AS seal
WORKDIR /seal
COPY seal/Cargo.toml seal/Cargo.lock ./
COPY seal/src ./src
RUN cargo test --release && cargo build --release

# ---- 2. Ruby base ----
FROM ruby:$RUBY_VERSION-slim AS base
WORKDIR /rails
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# ---- 3. Gems + assets ----
FROM base AS build
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile
COPY . .
RUN bundle exec bootsnap precompile app/ lib/ && \
    SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ---- 4. Final ----
FROM base
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails
COPY --from=seal /seal/target/release/uat-seal /rails/bin/uat-seal
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p db log storage tmp && chown -R rails:rails db log storage tmp
USER 1000:1000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
# rails server 會用 $PORT（Render 會自動提供），冇就用 3000
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
