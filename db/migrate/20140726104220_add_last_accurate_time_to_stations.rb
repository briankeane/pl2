class AddLastAccurateTimeToStations < ActiveRecord::Migration
  def change
    # TODO
    change_table(:stations) do |t|
      t.datetime :last_accurate_airtime
    end
  end
end
