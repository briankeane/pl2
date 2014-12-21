class CreatePresetsTable < ActiveRecord::Migration
  def change
    # TODO
    create_table(:presets) do |t|
      t.integer :user_id
      t.integer :station_id
    end
  end
end
