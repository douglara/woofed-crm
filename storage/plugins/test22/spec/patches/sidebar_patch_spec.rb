require 'rails_helper'

RSpec.describe 'Sidebar patch (test22 plugin)' do
  let(:original) { Rails.root.join('app/views/layouts/shared/_sidebar.html.erb').read }

  before { Plugins::FilePatch.clear_registry! }
  after  { Plugins::FilePatch.clear_registry! }

  it 'adds the world clocks menu item' do
    load Rails.root.join('storage/plugins/test22/app/views/layouts/shared/_sidebar.html.erb')
    result = Plugins::FilePatch.apply('app/views/layouts/shared/_sidebar.html.erb', original)

    expect(result).to include('account_world_clocks_path(Current.account)')
    expect(result).to include("icon: 'globe'")
    expect(result).to include('plugins.test22.world_clocks')
  end

  it 'does not modify the original file' do
    original_content = Rails.root.join('app/views/layouts/shared/_sidebar.html.erb').read
    expect(original_content).not_to include('world_clocks')
    expect(original_content).not_to include('globe')
  end
end
