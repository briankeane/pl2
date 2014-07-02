class CreateSpins < ActiveRecord::Migration
  def change
    create_table :spins do |t|
      t.integer :current_position
      t.integer :station_id
      t.datetime :estimated_airtime
      t.integer :audio_block_id
      
      t.timestamps
    end
  end
end
