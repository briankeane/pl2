class CreateCommercials < ActiveRecord::Migration
  def change
    create_table :commercials do |t|
      t.integer :sponsor_id
      t.integer :duration #in ms
      t.string  :key
      
      t.timestamps
    end
  end
end
