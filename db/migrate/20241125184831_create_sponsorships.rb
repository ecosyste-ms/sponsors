class CreateSponsorships < ActiveRecord::Migration[8.0]
  def change
    create_table :sponsorships do |t|
      t.references :funder, null: false, foreign_key: { to_table: :accounts }
      t.references :maintainer, null: false, foreign_key: { to_table: :accounts }
      t.string :status

      t.timestamps
    end
  end
end
