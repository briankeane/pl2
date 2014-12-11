class AddGenresTable < ActiveRecord::Migration
  def change
    # TODO
    create_table(:genres) do |t|
      t.integer :song_id
      t.string :genre
    end
  end
end
