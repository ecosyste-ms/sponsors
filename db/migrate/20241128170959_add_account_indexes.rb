class AddAccountIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :accounts, :has_sponsors_listing
    add_index :accounts, :sponsorships_count
    add_index :accounts, :sponsors_count
    add_index :accounts, :active_sponsorships_count
  end
end
