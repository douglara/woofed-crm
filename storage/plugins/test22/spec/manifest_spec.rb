require 'rails_helper'

RSpec.describe 'Plugin manifest' do
  it 'has correct name' do
    manifest = Rails.root.join('storage/plugins/test22/plugin.rb').read
    expect(manifest).to include('name')
    expect(manifest).to include("'test22'")
    expect(manifest).to include("'1.0.0'")
  end
end
