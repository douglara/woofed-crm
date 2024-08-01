# frozen_string_literal: true

class Accounts::Apps::EvolutionApis::Instance::SessionsRefreshStatusJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform
    Apps::EvolutionApi.connected.find_each do |evolution_api|
      Accounts::Apps::EvolutionApis::Instance::Delete.call(evolution_api)
    end
  end
end
