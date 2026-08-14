class Accounts::WorldClocksController < InternalController
  def index
    @time_zones = [
      { key: :brazil, zone: 'Brasilia', offset: '-03:00' },
      { key: :brisbane, zone: 'Brisbane', offset: '+10:00' },
      { key: :new_york, zone: 'America/New_York', offset: '-05:00' }
    ]
  end
end
