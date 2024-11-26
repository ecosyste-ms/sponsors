class AddIndexToAccountLogins < ActiveRecord::Migration[8.0]
  def change
    add_index :accounts, :login, unique: true
  end
end
