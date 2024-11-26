class AddActiveSponsorshipsCountToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :active_sponsorships_count, :integer, default: 0
  end
end
