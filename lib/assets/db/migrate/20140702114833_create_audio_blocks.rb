class CreateAudioBlocks < ActiveRecord::Migration
  def change
    create_table :audio_blocks do |t|
      t.string :type
      
      # shared
      t.string :key
      t.integer :duration
      t.datetime :estimated_airtime
      t.integer :commentary_preceding_overlap
      t.integer :song_preceding_overlap
      t.integer :commercial_preceding_overlap
      t.integer :commentary_following_overlap
      t.integer :commercial_following_overlap
      t.integer :song_following_overlap
      
      # commercial_blocks
      t.integer :cb_position

      # songs
      t.string :artist
      t.string :title
      t.string :album

      # commentary
      t.integer :station_id

      t.timestamps
    end
  end
end
