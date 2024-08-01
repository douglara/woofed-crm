class Accounts::Apps::EvolutionApis::Instance::DeleteDisconnectedWorker
  include Sidekiq::Worker

  def perform(evolution_api_id)
    evolution_api = Apps::EvolutionApi.find(evolution_api_id)
    Accounts::Apps::EvolutionApis::Instance::DeleteDisconnected.new(evolution_api).call
  end
end
