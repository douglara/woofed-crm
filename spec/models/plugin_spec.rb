# frozen_string_literal: true

# == Schema Information
#
# Table name: plugins
#
#  id         :string           not null, primary key
#  name       :string           not null
#  priority   :integer          default(0), not null
#  status     :string           default("active"), not null
#  version    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_plugins_on_status  (status)
#
require 'rails_helper'

RSpec.describe Plugin do
  describe 'validations' do
    it 'requires a name' do
      expect(build(:plugin, name: nil)).not_to be_valid
    end

    it 'accepts only active, inactive or failed as status' do
      Plugin::STATUSES.each do |status|
        expect(build(:plugin, status: status)).to be_valid
      end
      expect(build(:plugin, status: 'unknown')).not_to be_valid
    end

    it 'defaults status to active' do
      expect(Plugin.new(name: 'demo').status).to eq('active')
    end
  end

  describe '.active' do
    it 'returns only active plugins' do
      active = create(:plugin, status: 'active')
      create(:plugin, status: 'inactive')
      create(:plugin, status: 'failed')

      expect(Plugin.active).to contain_exactly(active)
    end
  end

  describe '#local_path and #installed_locally?' do
    let(:plugin) { build(:plugin, id: 'example') }

    it 'points to storage/plugins/<id> and reflects whether the folder exists' do
      expect(plugin.local_path).to eq(Rails.root.join('storage', 'plugins', 'example'))
      expect(plugin.installed_locally?).to be(false)

      FileUtils.mkdir_p(plugin.local_path)
      expect(plugin.installed_locally?).to be(true)
    ensure
      FileUtils.rm_rf(plugin.local_path)
    end
  end
end
