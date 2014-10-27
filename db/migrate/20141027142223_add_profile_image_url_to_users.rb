class AddProfileImageUrlToUsers < ActiveRecord::Migration
  def change
    # TODO
    change_table(:users) do |t|
      t.string :profile_image_url
    end
  end
end
