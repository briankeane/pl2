class AddEnIdToAudioBlocksTable < ActiveRecord::Migration
  def change
    # TODO
    change_table(:audio_blocks) do |t|
      t.string :en_id
    end
  end
end
