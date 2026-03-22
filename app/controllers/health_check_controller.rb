class HealthCheckController < ActionController::Base
  rescue_from(Exception) { render head: 503 }

  def show
    head 200
  end
end
