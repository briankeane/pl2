class CommercialLinks < ActiveRecord::Migration
  def change
    create_table :commercial_links do |t|
      t.integer :commercial_id
      t.integer :audio_block_id
    end
  end
end