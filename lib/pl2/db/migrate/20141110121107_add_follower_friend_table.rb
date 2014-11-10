class AddFollowerFriendTable < ActiveRecord::Migration
  def change
    # TODO

    create_table :twitter_friends do |t|
      t.integer :follower_uid
      t.integer :followed_station_id

      t.timestamps
    end
  end
end
