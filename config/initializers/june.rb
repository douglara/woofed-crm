if ENV['JUNE_KEY'].present?
  require 'june/analytics'

  Analytics = June::Analytics.new({
    write_key: "#{ENV['JUNE_KEY']}",
    on_error: proc { |_status, msg| print msg },
    stub: !Rails.env.production?
    })

end
