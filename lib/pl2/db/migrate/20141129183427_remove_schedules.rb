class RemoveSchedules < ActiveRecord::Migration
  def change
    # TODO
    drop_table :schedules

    change_table(:stations) do |t|
      t.remove :schedule_id
      t.integer :last_accurate_current_position
      t.integer :next_commercial_block_id
      t.datetime "current_playlist_end_time"
      t.datetime "original_playlist_end_time"
    end
  end
end
