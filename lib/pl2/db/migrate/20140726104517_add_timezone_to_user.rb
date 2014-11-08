class AddTimezoneToUser < ActiveRecord::Migration
  def change
    # TODO
    change_table(:users) do |t|
      t.string :timezone
    end
  end
end
