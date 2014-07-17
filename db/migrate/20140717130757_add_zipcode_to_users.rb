class AddZipcodeToUsers < ActiveRecord::Migration
  def change
    change_table(:users) do |t|
      t.string :zipcode
    end
  end
end
