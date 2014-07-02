class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :twitter
      t.integer :twitter_uid
      t.string :email
      t.integer :birth_year
      t.string :gender

      t.timestamps
    end
  end
end
