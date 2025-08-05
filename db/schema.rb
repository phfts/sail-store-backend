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

ActiveRecord::Schema[8.0].define(version: 2025_08_05_164533) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "absences", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "absence_type", default: "vacation"
    t.text "description"
    t.index ["absence_type"], name: "index_absences_on_absence_type"
    t.index ["seller_id"], name: "index_absences_on_seller_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "external_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "commission_levels", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "name", null: false
    t.decimal "achievement_percentage", precision: 5, scale: 2, null: false
    t.decimal "commission_percentage", precision: 5, scale: 2, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id", "achievement_percentage"], name: "index_commission_levels_on_store_id_and_achievement_percentage", unique: true
    t.index ["store_id"], name: "index_commission_levels_on_store_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "cnpj"
    t.text "address"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "goals", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.integer "goal_type"
    t.date "start_date"
    t.date "end_date"
    t.decimal "target_value"
    t.decimal "current_value"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id"], name: "index_goals_on_seller_id"
  end

  create_table "login_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "login_at"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_login_logs_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.decimal "unit_price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "external_id"
    t.bigint "seller_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id"], name: "index_orders_on_seller_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "external_id"
    t.string "name"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.decimal "value", precision: 10, scale: 2, null: false
    t.datetime "sold_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id"], name: "index_sales_on_seller_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.bigint "shift_id", null: false
    t.bigint "store_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date"
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
    t.datetime "active_until"
    t.string "external_id"
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

  add_foreign_key "absences", "sellers"
  add_foreign_key "commission_levels", "stores"
  add_foreign_key "goals", "sellers"
  add_foreign_key "login_logs", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "sellers"
  add_foreign_key "products", "categories"
  add_foreign_key "sales", "sellers"
  add_foreign_key "schedules", "sellers"
  add_foreign_key "schedules", "shifts"
  add_foreign_key "schedules", "stores"
  add_foreign_key "sellers", "stores"
  add_foreign_key "sellers", "users"
  add_foreign_key "shifts", "stores"
end
