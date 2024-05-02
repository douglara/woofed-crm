class AddPgVectorExtension < ActiveRecord::Migration[6.1]
  def change
    enable_extension 'vector'
  end
end
