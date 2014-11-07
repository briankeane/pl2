class AddStationIdToAudioBlocksForCommercialBlocks < ActiveRecord::Migration
  def change
    # TODO
    change_table(:audio_blocks) do |t|
      t.integer :station_id
    end
  end
end
