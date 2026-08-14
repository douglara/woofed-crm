require 'rails_helper'

RSpec.describe Accounts::WorldClocksController do
  describe '#index' do
    it 'assigns time zones for Brazil, Brisbane, and New York' do
      controller = described_class.new
      controller.index

      time_zones = controller.instance_variable_get(:@time_zones)
      expect(time_zones).to be_an(Array)
      expect(time_zones.map { |tz| tz[:key] }).to match_array(%i[brazil brisbane new_york])
    end

    it 'includes correct zone names' do
      controller = described_class.new
      controller.index

      zones = controller.instance_variable_get(:@time_zones)
      expect(zones.find { |tz| tz[:key] == :brazil }[:zone]).to eq('Brasilia')
      expect(zones.find { |tz| tz[:key] == :brisbane }[:zone]).to eq('Brisbane')
      expect(zones.find { |tz| tz[:key] == :new_york }[:zone]).to eq('America/New_York')
    end
  end
end
