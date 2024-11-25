class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :login, null: false
      t.datetime :last_synced_at
      t.jsonb :data, default: {}
      t.boolean :has_sponsors_listing, default: false
      t.integer :sponsors_count, default: 0
      t.integer :funded_count, default: 0

      t.timestamps
    end
  end
end
