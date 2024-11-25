class AddSponsorProfileToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :sponsor_profile, :jsonb, default: {}
  end
end
