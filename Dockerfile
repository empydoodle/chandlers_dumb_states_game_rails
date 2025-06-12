# syntax = docker/dockerfile:1

FROM registry.docker.com/library/ruby:3.0.7

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV \
  BUNDLE_DEPLOYMENT="1" \
  BUNDLE_PATH="/usr/local/bundle" \
  NODE_OPTIONS="--openssl-legacy-provider"

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips vim && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install node dependency
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# set env
ENV NVM_DIR=/root/.nvm

# install node
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install 22 && corepack enable yarn"

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN /bin/bash -c "bundle config set frozen false && bundle install"
RUN rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git
RUN /bin/bash -c "bundle exec bootsnap precompile --gemfile"

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN /bin/bash -c "bundle exec bootsnap precompile app/ lib/"

# Update JS dependencies
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && npx browserslist@latest --update-db && npm_config_yes=true npx yarn-audit-fix"

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile"

# set ENTRYPOINT for reloading nvm-environment
ENTRYPOINT ["bash", "-c", "source $NVM_DIR/nvm.sh && ./bin/rails db:prepare && ./bin/rails webpacker:install && exec \"$@\"", "--"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["/bin/bash", "-c", "./bin/rails", "server"]
