# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2024_11_25_190110) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "login", null: false
    t.datetime "last_synced_at"
    t.jsonb "data", default: {}
    t.boolean "has_sponsors_listing", default: false
    t.integer "sponsors_count", default: 0
    t.integer "funded_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "sponsor_profile", default: {}
    t.integer "sponsorships_count", default: 0
  end

  create_table "sponsorships", force: :cascade do |t|
    t.bigint "funder_id", null: false
    t.bigint "maintainer_id", null: false
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["funder_id"], name: "index_sponsorships_on_funder_id"
    t.index ["maintainer_id"], name: "index_sponsorships_on_maintainer_id"
  end

  add_foreign_key "sponsorships", "accounts", column: "funder_id"
  add_foreign_key "sponsorships", "accounts", column: "maintainer_id"
end
