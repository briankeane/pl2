class ChangeStationIdToScheduleIdForManyModels < ActiveRecord::Migration
  def change
    # TODO
    change_table(:audio_blocks) do |t|
      t.remove :station_id
      t.integer :schedule_id
    end
    
    change_table(:spins) do |t|
      t.remove :station_id
      t.integer :schedule_id
    end
  end
end
