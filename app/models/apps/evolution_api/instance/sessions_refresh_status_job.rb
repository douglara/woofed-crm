# frozen_string_literal: true

class Apps::EvolutionApi::Instance::SessionsRefreshStatusJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform
    Apps::EvolutionApi.connected.find_each do |evolution_api|
      Apps::EvolutionApi::Instance::DeleteDisconnected.new(evolution_api).call
    end
  end
end
