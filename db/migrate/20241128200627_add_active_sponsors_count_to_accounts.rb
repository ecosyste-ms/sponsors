class AddActiveSponsorsCountToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :active_sponsors_count, :integer, default: 0
  end
end
