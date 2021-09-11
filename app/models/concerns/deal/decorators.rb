module Deal::Decorators
  def next_action_format
    flow_items.activities_not_done.first.record.due_format rescue nil
  end
end
