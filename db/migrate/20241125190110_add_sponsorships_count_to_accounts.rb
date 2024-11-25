class AddSponsorshipsCountToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :sponsorships_count, :integer, default: 0
  end
end
