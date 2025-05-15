module Event::Decorators
  include ActionView::Helpers::DateHelper

  def scheduled_at_format
    scheduled_at.to_fs(:short)
  rescue StandardError
    ''
  end

  def scheduled_at_format_distance
    distance_of_time_in_words(Time.current, scheduled_at, scope: 'datetime.distance_in_words.short')
  end
end
