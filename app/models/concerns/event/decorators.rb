module Event::Decorators
  include ActionView::Helpers::DateHelper

  def scheduled_at_format
    scheduled_at.to_s(:short)
  rescue StandardError
    ''
  end

  def scheduled_at_format_distance
    distance_of_time_in_words(scheduled_at - Time.current).sub('aproximadamente', '').strip
  end

end
