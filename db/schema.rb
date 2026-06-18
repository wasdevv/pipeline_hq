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

ActiveRecord::Schema[8.1].define(version: 2026_06_18_035039) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "industry"
    t.string "name", limit: 120
    t.text "notes"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["name"], name: "index_accounts_on_name"
  end

  create_table "activities", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "deal_id", null: false
    t.string "kind", limit: 30
    t.datetime "occurred_at"
    t.string "subject", limit: 160
    t.datetime "updated_at", null: false
    t.index ["deal_id"], name: "index_activities_on_deal_id"
    t.index ["kind"], name: "index_activities_on_kind"
    t.index ["occurred_at"], name: "index_activities_on_occurred_at"
  end

  create_table "auth_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address"
    t.string "ip_address"
    t.string "kind", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "user_agent"
    t.bigint "user_id"
    t.index ["ip_address"], name: "index_auth_events_on_ip_address"
    t.index ["kind", "created_at"], name: "index_auth_events_on_kind_and_created_at"
    t.index ["metadata"], name: "index_auth_events_on_metadata", using: :gin
    t.index ["user_id", "created_at"], name: "index_auth_events_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_auth_events_on_user_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", limit: 120
    t.string "phone"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_contacts_on_account_id"
    t.index ["email"], name: "index_contacts_on_email"
  end

  create_table "deals", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "amount_cents"
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.string "currency"
    t.date "expected_close_on"
    t.bigint "stage_id", null: false
    t.string "status"
    t.string "title", limit: 160
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_deals_on_account_id"
    t.index ["contact_id"], name: "index_deals_on_contact_id"
    t.index ["stage_id"], name: "index_deals_on_stage_id"
    t.index ["status"], name: "index_deals_on_status"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "last_active_at"
    t.datetime "otp_verified_at"
    t.datetime "sudo_until"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id", "last_active_at"], name: "index_sessions_on_user_id_and_last_active_at"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "stages", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "name", limit: 60
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_stages_on_position"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.string "name"
    t.string "otp_backup_codes", default: [], null: false, array: true
    t.datetime "otp_enabled_at"
    t.string "otp_secret"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmed_at"], name: "idx_users_unconfirmed", where: "(confirmed_at IS NULL)"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["locked_at"], name: "idx_users_locked", where: "(locked_at IS NOT NULL)"
  end

  add_foreign_key "activities", "deals"
  add_foreign_key "auth_events", "users"
  add_foreign_key "contacts", "accounts"
  add_foreign_key "deals", "accounts"
  add_foreign_key "deals", "contacts"
  add_foreign_key "deals", "stages"
  add_foreign_key "sessions", "users"
end
