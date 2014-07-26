class SeparatePlaylistsFromStations < ActiveRecord::Migration
  def change
    # TODO
    change_table(:stations) do |t|
      t.remove :current_playlist_end_time, :original_playlist_end_time
      t.remove :next_commercial_block_id, :last_accurate_airtime
      t.integer :schedule_id
    end

    create_table(:schedules) do |t|
      t.integer :station_id
      t.datetime :current_playlist_end_time
      t.datetime :original_playlist_end_time
      t.integer :next_commercial_block_id
      t.datetime :last_accurate_airtime
    end

  end
end
