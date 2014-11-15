class AddAirtimeToCommercialBlock < ActiveRecord::Migration
  def change
    change_table(:audio_blocks) do |t|
      t.datetime :airtime
    end
  end
end
