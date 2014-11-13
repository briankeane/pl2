class AddLastCommercialBlockToStationsTable < ActiveRecord::Migration
  def change
    # TODO
    change_table(:stations) do |t|
      t.integer :lastCommercialBlockAired
    end
  end
end
