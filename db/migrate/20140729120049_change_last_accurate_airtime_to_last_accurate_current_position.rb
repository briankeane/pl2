class ChangeLastAccurateAirtimeToLastAccurateCurrentPosition < ActiveRecord::Migration
  def change
    # TODO
    change_table(:schedules) do |t|
      t.remove :last_accurate_airtime
      t.integer :last_accurate_current_position
    end

  end
end
