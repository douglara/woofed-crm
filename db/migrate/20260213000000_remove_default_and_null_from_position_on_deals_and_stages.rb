# frozen_string_literal: true

class RemoveDefaultAndNullFromPositionOnDealsAndStages < ActiveRecord::Migration[7.1]
  def change
    change_column_default :deals, :position, from: 1, to: nil
    change_column_null :deals, :position, true

    change_column_default :stages, :position, from: 1, to: nil
    change_column_null :stages, :position, true
  end
end
