module Activity::Decorators
  def icon_key
    activity_kind.icon_key
  end

  def due_format
    due.to_s(:short) rescue ''
  end
end
