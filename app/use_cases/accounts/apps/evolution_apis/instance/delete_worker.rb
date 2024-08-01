class Accounts::Apps::EvolutionApis::Instance::DeleteWorker
  include Sidekiq::Worker
  sidekiq_options queue: :evolution_api_delete_instance

  def perform(evolution_api_id)
    evolution_api = Apps::EvolutionApi.find(evolution_api_id)
    Accounts::Apps::EvolutionApis::Instance::Delete.call(evolution_api)
  end
end
