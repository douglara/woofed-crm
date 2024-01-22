Rails.application.config.session_store :cookie_store,
  :key => "_#{ENV.fetch('DOMAIN', 'woofedcrm')}_session",
  :domain => :all,
  :same_site => :none,
  :secure => :true,
  :tld_length => 2