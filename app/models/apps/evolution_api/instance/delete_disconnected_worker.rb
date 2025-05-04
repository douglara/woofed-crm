class Apps::EvolutionApi::Instance::DeleteDisconnectedWorker
  include Sidekiq::Worker

  def perform(evolution_api_id)
    evolution_api = Apps::EvolutionApi.find_by_id(evolution_api_id)
    Apps::EvolutionApi::Instance::DeleteDisconnected.new(evolution_api).call
  end
end
