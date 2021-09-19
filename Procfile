release: rails db:migrate db:seed --trace
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq