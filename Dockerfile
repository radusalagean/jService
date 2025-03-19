ARG RUBY_VERSION=3.4.2
FROM ruby:$RUBY_VERSION-slim as builder

# Install essential Linux packages
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    libyaml-dev \
    git \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

ARG COMMIT_HASH
ENV COMMIT_HASH=$COMMIT_HASH

ARG RAILS_ENV
ENV RAILS_ENV=$RAILS_ENV

ARG RACK_ENV
ENV RACK_ENV=$RACK_ENV

ARG POSTGRES_USER
ENV POSTGRES_USER=$POSTGRES_USER

ARG POSTGRES_PASSWORD_FILE
ENV POSTGRES_PASSWORD_FILE=$POSTGRES_PASSWORD_FILE

ARG POSTGRES_DB
ENV POSTGRES_DB=$POSTGRES_DB

ARG POSTGRES_HOST
ENV POSTGRES_HOST=$POSTGRES_HOST

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the rest of the application
COPY . .

# Precompile assets
RUN --mount=type=secret,id=db_password \
    bundle exec rails assets:precompile

# Production stage
FROM ruby:$RUBY_VERSION-slim

# Install essential Linux packages
RUN apt-get update -qq && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application from builder
COPY --from=builder /app /app

# Set environment variables
ENV RAILS_SERVE_STATIC_FILES=true

# Add database setup script
COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh

# Expose port 3000
EXPOSE 3000

# Use entrypoint script to handle database setup and startup
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
