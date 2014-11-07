class CreateLogEntries < ActiveRecord::Migration
  def change
    create_table :log_entries do |t|
      t.string :type
      t.integer :station_id
      t.integer :current_position
      t.integer :audio_block_id
      t.datetime :airtime
      t.integer :listeners_at_start
      t.integer :listeners_at_finish
      t.integer :duration   #in millisecs from start of play to start of next spin
    end
  end
end