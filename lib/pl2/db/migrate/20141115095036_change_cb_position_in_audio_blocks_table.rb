class ChangeCbPositionInAudioBlocksTable < ActiveRecord::Migration
  def change
    # TODO
    change_table(:audio_blocks) do |t|
      t.remove :cb_position
      t.integer :current_position
    end
  end
end
