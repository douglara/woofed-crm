# frozen_string_literal: true

Rails.application.config.session_store :cookie_store,
                                       key: "_woofedcrm_#{Rails.env}_session",
                                       domain: :all,
                                       same_site: :none,
                                       secure: true,
                                       tld_length: 3 if ENV.fetch('FRONTEND_URL', '').include?('https')
