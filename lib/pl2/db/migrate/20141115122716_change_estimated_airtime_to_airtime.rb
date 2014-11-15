class ChangeEstimatedAirtimeToAirtime < ActiveRecord::Migration
  def change
    # TODO
    rename_column :spins, :estimated_airtime, :airtime
  end
end
