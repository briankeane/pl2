class CreateListeningSessionsTable < ActiveRecord::Migration
  def change
    # TODO
    create_table(:listening_sessions) do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.integer :station_id
      t.integer :user_id
    end

    change_table(:stations) do |t|
      t.float :average_daily_listeners
      t.date :average_daily_listeners_calculation_date
    end
  end
end
