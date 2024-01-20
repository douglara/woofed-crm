Rails.application.config.session_store :cookie_store,
  :key => '_woofedcrm_session',
  :domain => :all,
  :same_site => :none,
  :tld_length => 2 if Rails.env.production?