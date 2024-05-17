FROM debian:trixie


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
ENV MOTOR_AUTH_PASSWORD=admin
ENV PORT=3001
ENV ENABLE_USER_SIGNUP=true
ENV FRONTEND_URL=http://0.0.0.0:3001

RUN apt-get update && apt-get install -y \
  build-essential \
  libpq-dev \
  redis-server \
  supervisor \
  postgresql-16-pgvector \
  libssl-dev openssl \
  wget \
  procps curl ca-certificates gnupg2 \
  libz-dev \
  git

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - \
  && apt-get install -y nodejs && npm install --global yarn
RUN npm config get registry prints: https://registry.npmjs.org

## Install Ruby
ENV OPENSSL_VERSION=1.1.1v
RUN wget https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz \
  && tar -xzf openssl-$OPENSSL_VERSION.tar.gz \
  && cd openssl-$OPENSSL_VERSION \
  && ./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl shared zlib \
  && make -j$(nproc) \
  && make install \
  && cd .. \
  && rm -rf openssl-$OPENSSL_VERSION.tar.gz openssl-$OPENSSL_VERSION

RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - \
    && curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - \
    && curl -sSL https://get.rvm.io | bash -s stable
RUN echo 'export PATH="/usr/local/rvm/bin:$PATH"' >> /etc/profile.d/rvm.sh \
    && echo '. /usr/local/rvm/scripts/rvm' >> /etc/profile.d/rvm.sh \
    && /bin/sh -c ". /etc/profile.d/rvm.sh && rvm requirements" \
    && /bin/sh -c ". /etc/profile.d/rvm.sh && rvm install 3.0.0 --with-openssl-dir=/usr/local/openssl" \
    && /bin/sh -c ". /etc/profile.d/rvm.sh && rvm use 3.0.0 --default"
ENV PATH="/usr/local/rvm/rubies/ruby-3.0.0/bin:/usr/local/rvm/bin:${PATH}"
RUN ruby -v && openssl version
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
EXPOSE 3001 5432 6379
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]