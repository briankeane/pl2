class DeleteCommercialLeadsIn < ActiveRecord::Migration
  def change
    remove_column :spins, :commercial_leads_in
  end
end
