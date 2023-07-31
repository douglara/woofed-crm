Rails.application.config.session_store :cookie_store,
  :key => '_woofedcrm_session',
  :domain => :all,
  :same_site => :none,
  :secure => :true,
  :tld_length => 2