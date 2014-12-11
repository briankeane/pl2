class AddGenresTable < ActiveRecord::Migration
  def change
    # TODO
    create_table(:genres) do |t|
      t.integer :audio_block_id
      t.string :name
    end
  end
end
