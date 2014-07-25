class AddTimezoneToUserAndAirtimesCurrentToStation < ActiveRecord::Migration
  def change
    change_table(:stations) do |t|
      t.boolean :airtimes_current
      t.string :timezone
    end
  end
end
