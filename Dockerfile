FROM ruby:3.3.4 as app

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV SECRET_KEY_BASE e3a0972a1f0e0d3850d56cead8f4bccd0b41f8cfeff9f1664aea00518db989ff5bace371f2a9ea7299dbbf08f0302811dbcb9141

RUN apt-get update -qq \
        && apt-get install -y \
        build-essential libpq-dev libnss3-dev nodejs \
        postgresql postgresql-client \
        graphviz \
        netcat-traditional software-properties-common \
        imagemagick libvips libvips-dev libvips-tools
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - \
        && apt-get install -y nodejs npm && npm install --global yarn

RUN npm config get registry prints: https://registry.npmjs.org

COPY Gemfile* /tmp/
WORKDIR /tmp
RUN gem install bundler
RUN bundle install

ENV app /app
RUN mkdir $app
WORKDIR $app

# Copy the main application.
COPY . ./

# Install and build javascript dependences
RUN yarn build
RUN yarn install --check-files

# Precompile Rails assets (plus Webpack)
RUN NODE_OPTIONS=--openssl-legacy-provider bundle exec rake assets:precompile

# Install node dependences
RUN npm i -g flat

RUN echo "Waiting for postgres to become ready...."
RUN sleep 10

RUN chmod +x /app/bin/easyinstall

CMD bundle exec rails db:create; bundle exec rails db:migrate; bundle exec puma -C config/puma.rb