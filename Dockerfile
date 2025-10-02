# Dockerfile for Collaged Rails Application
FROM ruby:3.3.0-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libvips-dev \
    imagemagick \
    libmagickwand-dev \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# Copy application code
COPY . .

# Precompile assets
RUN bundle exec rails assets:precompile

# Create storage directories
RUN mkdir -p storage tmp/storage tmp/pids

# Expose port
EXPOSE 3000

# Set environment variables
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# Start server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
