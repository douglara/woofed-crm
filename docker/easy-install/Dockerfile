FROM ruby:3.3.4

ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=password
ENV POSTGRES_DB=woofed_crm_production
ENV DATABASE_URL=postgres://postgres:password@localhost/woofed_crm_production
ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV SECRET_KEY_BASE dummy_secret_key_base
ENV REDIS_URL=redis://localhost:6379/0
ENV MOTOR_AUTH_USERNAME=lovewoofed
ENV MOTOR_AUTH_PASSWORD=lovewoofed
ENV PORT=80
ENV ENABLE_USER_SIGNUP=false
ENV FRONTEND_URL=http://0.0.0.0

RUN apt-get update && apt-get install -y \
  build-essential \
  libpq-dev \
  redis-server \
  supervisor \
  wget \
  procps \
  curl \
  ca-certificates \
  gnupg2 \
  libz-dev \
  git

# Install postgresql 16 and pgvector
RUN echo "deb http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
  && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt-get update && apt-get install -y \
  postgresql-16 \
  postgresql-16-pgvector

RUN curl -sL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y nodejs && npm install --global yarn

RUN ruby -v
RUN gem install bundler

## Install app
WORKDIR /app
COPY . /app
RUN chmod +x /app/bin/easyinstall
RUN bundle install
RUN yarn build
RUN yarn install --check-files
RUN bundle exec rake assets:precompile

## Postgres
RUN mkdir -p /app/storage/postgresql/data
RUN chown -R postgres:postgres /app/storage/postgresql/data
USER postgres
RUN /usr/lib/postgresql/16/bin/initdb -E UTF8 -D /app/storage/postgresql/data
USER root

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80 5432 6379

HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=5 \
  CMD ["curl", "-f", "http://localhost/up"]

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
