class AddAlbumArtworkUrlToSongs < ActiveRecord::Migration
  def change
    # TODO
    change_table(:audio_blocks) do |t|
      t.string :album_artwork_url
    end
  end
end
