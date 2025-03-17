FROM ruby:3.1-slim as builder

# Install essential Linux packages
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    git \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the rest of the application
COPY . .

# Precompile assets
RUN bundle exec rake assets:precompile

# Production stage
FROM ruby:3.1.2-slim

# Install essential Linux packages
RUN apt-get update -qq && apt-get install -y \
    libpq-dev \
    nodejs \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application from builder
COPY --from=builder /app /app

# Copy precompiled assets
COPY --from=builder /app/public/assets /app/public/assets

# Set environment variables
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true

# Add database setup script
COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh

# Expose port 3000
EXPOSE 3000

# Use entrypoint script to handle database setup and startup
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
