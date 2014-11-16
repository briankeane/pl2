class FixlastCommercialBlockAiredName < ActiveRecord::Migration
  def change
    # TODO
    rename_column :stations, :lastCommercialBlockAired, :last_commercial_block_aired
  end
end
