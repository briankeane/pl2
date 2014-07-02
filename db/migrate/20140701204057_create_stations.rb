class CreateStations < ActiveRecord::Migration
  def change  

    create_table :stations do |t|
      t.integer :user_id
      t.integer :secs_of_commercial_per_hour
      t.integer :spins_per_week
      t.datetime :current_playlist_end_time
      t.datetime :original_playlist_end_time
      t.integer :next_commercial_block_id

      t.timestamps
    end
  end
end
