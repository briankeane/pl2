class AddEchonestIdToAudioBlocksTable < ActiveRecord::Migration
  def change
    # TODO
    change_table(:audio_blocks) do |t|
      t.string :echonest_id
    end
  end
end
