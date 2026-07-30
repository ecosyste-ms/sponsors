class AddHiddenToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :hidden, :boolean, default: false, null: false
  end
end
