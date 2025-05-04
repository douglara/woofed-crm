class Apps::EvolutionApi::Instance::SetAlwaysOnlineStatusToFalseJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform
    Apps::EvolutionApi.connected.find_each do |evolution_api|
      Apps::EvolutionApi::Instance::UpdateSettings.call(evolution_api)
    end
  end
end
