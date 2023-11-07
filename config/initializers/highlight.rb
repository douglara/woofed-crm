if ENV['HIGHLIGHT_PROJECT_ID'].present?
  require "highlight"

  Highlight::H.new(ENV['HIGHLIGHT_PROJECT_ID']) do |c|
    c.service_name = ENV['HIGHLIGHT_APP_NAME']
    c.service_version = "git-sha"
  end
  
  # or alternatively extend it to log with both
  highlightLogger = Highlight::Logger.new(nil)
  Rails.logger.extend(ActiveSupport::Logger.broadcast(highlightLogger))

end
