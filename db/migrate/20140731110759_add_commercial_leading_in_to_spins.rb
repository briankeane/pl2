class AddCommercialLeadingInToSpins < ActiveRecord::Migration
  def change
    # TODO
    change_table(:spins) do |t|
      t.boolean :commercial_leads_in
    end

  end
end
