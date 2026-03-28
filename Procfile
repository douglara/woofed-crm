release: bin/boot rails db:seed --trace
worker: bundle exec sidekiq -C config/sidekiq.yml
good_job: bundle exec good_job