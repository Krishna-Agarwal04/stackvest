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

ActiveRecord::Schema[8.1].define(version: 2026_05_21_090246) do
  create_table "bids", force: :cascade do |t|
    t.decimal "amount"
    t.string "bidder_name"
    t.datetime "created_at", null: false
    t.integer "stack_asset_id", null: false
    t.datetime "timestamp"
    t.datetime "updated_at", null: false
    t.index ["stack_asset_id"], name: "index_bids_on_stack_asset_id"
  end

  create_table "stack_assets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "current_bid"
    t.text "description"
    t.decimal "earnings"
    t.string "highest_bidder"
    t.string "image_url"
    t.decimal "monthly_roi"
    t.string "name"
    t.string "owner_name"
    t.string "risk_level"
    t.string "status"
    t.string "technologies"
    t.datetime "updated_at", null: false
    t.decimal "valuation"
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "timestamp"
    t.string "transaction_type"
    t.datetime "updated_at", null: false
  end

  create_table "wallets", force: :cascade do |t|
    t.decimal "balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "bids", "stack_assets"
end
