FROM ruby:3.3.4 as app

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV SECRET_KEY_BASE e3a0972a1f0e0d3850d56cead8f4bccd0b41f8cfeff9f1664aea00518db989ff5bace371f2a9ea7299dbbf08f0302811dbcb9141
ENV PORT=80

RUN apt-get update -qq \
        && apt-get install -y \
        build-essential libpq-dev libnss3-dev nodejs \
        postgresql postgresql-client \
        graphviz \
        netcat-traditional software-properties-common \
        imagemagick libvips libvips-dev libvips-tools
RUN curl -sL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g yarn

RUN npm config get registry prints: https://registry.npmjs.org

COPY Gemfile* /tmp/
WORKDIR /tmp
RUN gem install bundler
RUN bundle install

ENV app /app
RUN mkdir $app
WORKDIR $app

# --- AI agent (agno) Python runtime -------------------------------------------
# The woofed-ai-agent role (config/deploy.yml) starts the AgentOS from THIS same
# image instead of Rails. uv (Astral) manages an isolated venv at ai-agent/.venv
# and auto-downloads the Python 3.12 pinned by ai-agent/pyproject.toml
# (requires-python >=3.12). Dependencies install in their own layer so they cache
# independently of the Rails app code below.
COPY --from=ghcr.io/astral-sh/uv:0.5 /uv /uvx /usr/local/bin/
COPY ai-agent/pyproject.toml ai-agent/uv.lock ai-agent/
RUN uv python install 3.12 \
    && uv sync --frozen --no-install-project --directory ai-agent
ENV UV_NO_SYNC=1 \
    PYTHONUNBUFFERED=1
# ------------------------------------------------------------------------------

# Copy the main application.
COPY . ./

# Install and build javascript dependences
RUN yarn build
RUN yarn install --check-files

# Precompile Rails assets (Vite)
RUN bundle exec rake assets:precompile

# Install node dependences
RUN npm i -g flat

RUN echo "Waiting for postgres to become ready...."
RUN sleep 10

RUN chmod +x /app/bin/easyinstall

EXPOSE 80
# HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
#   CMD ["curl", "-f", "http://localhost/up"]

CMD bundle exec rails db:create; bundle exec rails db:migrate; bundle exec puma -C config/puma.rb
