class CommercialsCommercialBlocks < ActiveRecord::Migration
  def change
    create_table :commercials_commercial_blocks, :id => false do |t|
      t.references :commercials, :commercial_blocks
    end
  end
end
