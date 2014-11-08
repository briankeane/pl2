class CreateSpinFrequencies < ActiveRecord::Migration
  def change
    create_table :spin_frequencies do |t|
      t.integer :song_id
      t.integer :station_id
      t.integer :spins_per_week
    end
  end
end
