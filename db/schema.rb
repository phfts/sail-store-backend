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

ActiveRecord::Schema[8.0].define(version: 2025_08_02_123721) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "login_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "login_at"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_login_logs_on_user_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.bigint "shift_id", null: false
    t.bigint "store_id", null: false
    t.integer "day_of_week"
    t.integer "week_number"
    t.integer "year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id"], name: "index_schedules_on_seller_id"
    t.index ["shift_id"], name: "index_schedules_on_shift_id"
    t.index ["store_id"], name: "index_schedules_on_store_id"
  end

  create_table "sellers", force: :cascade do |t|
    t.bigint "user_id"
    t.string "whatsapp"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "store_id", null: false
    t.string "name"
    t.boolean "store_admin"
    t.index ["name", "user_id"], name: "index_sellers_on_name_and_user_id", unique: true, where: "((name IS NOT NULL) AND (user_id IS NOT NULL))"
    t.index ["store_id"], name: "index_sellers_on_store_id"
    t.index ["user_id"], name: "index_sellers_on_user_id"
  end

  create_table "shifts", force: :cascade do |t|
    t.string "name"
    t.time "start_time"
    t.time "end_time"
    t.bigint "store_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_shifts_on_store_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "name"
    t.string "cnpj"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "vacations", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id"], name: "index_vacations_on_seller_id"
  end

  add_foreign_key "login_logs", "users"
  add_foreign_key "schedules", "sellers"
  add_foreign_key "schedules", "shifts"
  add_foreign_key "schedules", "stores"
  add_foreign_key "sellers", "stores"
  add_foreign_key "sellers", "users"
  add_foreign_key "shifts", "stores"
  add_foreign_key "vacations", "sellers"
end
