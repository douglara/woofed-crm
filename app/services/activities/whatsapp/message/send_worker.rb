class Activities::Whatsapp::Message::SendWorker
  include Sidekiq::Worker

  def perform(activity_id)
    activity = Activity.find(activity_id)
    Activities::Whatsapp::Message::Send.new(activity).perform
  end
end