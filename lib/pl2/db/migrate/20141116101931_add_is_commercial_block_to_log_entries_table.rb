class AddIsCommercialBlockToLogEntriesTable < ActiveRecord::Migration
  def change
    # TODO
    change_table(:log_entries) do |t|
      t.boolean :is_commercial_block
    end
  end
end
