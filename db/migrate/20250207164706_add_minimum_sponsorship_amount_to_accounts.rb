class AddMinimumSponsorshipAmountToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :minimum_sponsorship_amount, :integer
  end
end
