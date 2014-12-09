class CreateListeningSessionsTable < ActiveRecord::Migration
  def change
    # TODO
    create_table(:listening_sessions) do |t|
      t.integer :starting_current_position
      t.integer :ending_current_position
      t.datetime :start_time
      t.datetime :end_time
      t.integer :station_id
      t.integer :user_id
    end

    change_table(:stations) do |t|
      t.float :daily_average_listeners
      t.date :daily_average_calculation_date
    end
  end
end
