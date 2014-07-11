class AddEchoIdToAudioBlocksTable < ActiveRecord::Migration
  def change
    # TODO
    change_table(:audio_blocks) do |t|
      t.string :echo_id
    end
  end
end
