module Event::Decorators
  include ActionView::Helpers::DateHelper

  def due_format
    due.to_s(:short) rescue ''
  end

  def due_format_distance
    distance_of_time_in_words(self.due - Time.current).sub('aproximadamente', '').strip
  end
end
