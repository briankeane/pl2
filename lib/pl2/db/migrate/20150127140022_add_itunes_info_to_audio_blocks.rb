class AddItunesInfoToAudioBlocks < ActiveRecord::Migration
  def change
    # TODO
    change_table(:audio_blocks) do |t|
      t.string :itunes_track_view_url
    end
  end
end
