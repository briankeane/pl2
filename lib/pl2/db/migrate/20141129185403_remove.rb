class Remove < ActiveRecord::Migration
  def change
    # TODO
    change_table(:audio_blocks) do |t|
      t.remove :schedule_id
    end

    change_table(:spins) do |t|
      t.rename :schedule_id, :station_id
    end

    change_table(:users) do |t|
      t.integer "station_id"
    end
  end
end
