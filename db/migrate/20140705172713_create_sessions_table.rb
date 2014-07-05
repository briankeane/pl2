class CreateSessionsTable < ActiveRecord::Migration
  def change
    create_table :sessions do |t|
      t.string :session_id
      t.integer :user_id
    end
  end
end
