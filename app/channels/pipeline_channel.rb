class PipelineChannel < ApplicationCable::Channel
  def subscribed
    stream_from "pipeline_#{params[:pipeline_id]}"
  end

  def unsubscribed
    stop_all_streams
  end
end
