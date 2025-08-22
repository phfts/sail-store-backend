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

ActiveRecord::Schema[8.0].define(version: 2025_08_22_181036) do
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

  create_table "adjustments", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.bigint "store_id", null: false
    t.bigint "company_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date", default: -> { "CURRENT_DATE" }
    t.index ["company_id"], name: "index_adjustments_on_company_id"
    t.index ["created_at"], name: "index_adjustments_on_created_at"
    t.index ["seller_id", "created_at"], name: "index_adjustments_on_seller_id_and_created_at"
    t.index ["seller_id"], name: "index_adjustments_on_seller_id"
    t.index ["store_id", "created_at"], name: "index_adjustments_on_store_id_and_created_at"
    t.index ["store_id"], name: "index_adjustments_on_store_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "external_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "products_count", default: 0, null: false
    t.bigint "company_id", null: false
    t.index ["company_id", "external_id"], name: "index_categories_on_company_id_and_external_id", unique: true, where: "(company_id IS NOT NULL)"
    t.index ["company_id"], name: "index_categories_on_company_id"
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
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.text "description"
    t.boolean "simplified_frontend", default: false, null: false
    t.index ["slug"], name: "index_companies_on_slug", unique: true
  end

  create_table "exchanges", force: :cascade do |t|
    t.string "external_id"
    t.string "voucher_number"
    t.decimal "voucher_value"
    t.string "original_document"
    t.string "new_document"
    t.string "customer_code"
    t.string "exchange_type"
    t.boolean "is_credit"
    t.datetime "processed_at"
    t.bigint "seller_id"
    t.bigint "original_order_id"
    t.bigint "new_order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_exchanges_on_external_id", unique: true
    t.index ["new_order_id"], name: "index_exchanges_on_new_order_id"
    t.index ["original_order_id"], name: "index_exchanges_on_original_order_id"
    t.index ["seller_id"], name: "index_exchanges_on_seller_id"
  end

  create_table "goals", force: :cascade do |t|
    t.bigint "seller_id"
    t.integer "goal_type"
    t.date "start_date"
    t.date "end_date"
    t.decimal "target_value"
    t.decimal "current_value"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "goal_scope"
    t.bigint "store_id"
    t.index ["seller_id"], name: "index_goals_on_seller_id"
    t.index ["store_id", "goal_scope"], name: "index_goals_on_store_id_and_goal_scope"
    t.index ["store_id"], name: "index_goals_on_store_id"
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
    t.bigint "store_id"
    t.string "external_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["store_id"], name: "index_order_items_on_store_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "external_id", null: false
    t.bigint "seller_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "sold_at"
    t.bigint "store_id", null: false
    t.index ["seller_id", "external_id"], name: "index_orders_on_seller_id_and_external_id", where: "(external_id IS NOT NULL)"
    t.index ["seller_id"], name: "index_orders_on_seller_id"
    t.index ["store_id", "external_id"], name: "index_orders_on_store_id_and_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["store_id"], name: "index_orders_on_store_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "external_id"
    t.string "name"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sku"
    t.index ["category_id"], name: "index_products_on_category_id"
  end

  create_table "queue_items", force: :cascade do |t|
    t.bigint "seller_id"
    t.bigint "store_id", null: false
    t.bigint "company_id", null: false
    t.string "status", default: "waiting", null: false
    t.integer "priority", default: 1, null: false
    t.text "notes"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_queue_items_on_company_id"
    t.index ["created_at"], name: "index_queue_items_on_created_at"
    t.index ["seller_id", "status"], name: "index_queue_items_on_seller_id_and_status"
    t.index ["seller_id"], name: "index_queue_items_on_seller_id"
    t.index ["store_id", "status"], name: "index_queue_items_on_store_id_and_status"
    t.index ["store_id"], name: "index_queue_items_on_store_id"
  end

  create_table "returns", force: :cascade do |t|
    t.string "external_id"
    t.string "original_sale_id"
    t.string "product_external_id"
    t.string "original_transaction"
    t.string "return_transaction"
    t.decimal "quantity_returned"
    t.datetime "processed_at"
    t.bigint "original_order_id"
    t.bigint "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_returns_on_external_id", unique: true
    t.index ["original_order_id"], name: "index_returns_on_original_order_id"
    t.index ["product_id"], name: "index_returns_on_product_id"
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
    t.bigint "company_id", null: false
    t.boolean "is_busy", default: false
    t.integer "queue_order", default: 0
    t.index ["company_id", "external_id"], name: "index_sellers_on_company_id_and_external_id", unique: true, where: "(company_id IS NOT NULL)"
    t.index ["company_id"], name: "index_sellers_on_company_id"
    t.index ["name", "user_id"], name: "index_sellers_on_name_and_user_id", unique: true, where: "((name IS NOT NULL) AND (user_id IS NOT NULL))"
    t.index ["store_id", "queue_order"], name: "index_sellers_on_store_id_and_queue_order"
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
    t.string "external_id"
    t.bigint "company_id", null: false
    t.boolean "hide_ranking", default: false, null: false
    t.index ["company_id"], name: "index_stores_on_company_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "store_admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["store_admin"], name: "index_users_on_store_admin"
  end

  add_foreign_key "absences", "sellers", on_delete: :cascade
  add_foreign_key "adjustments", "companies", on_delete: :cascade
  add_foreign_key "adjustments", "sellers"
  add_foreign_key "adjustments", "stores"
  add_foreign_key "categories", "companies", on_delete: :cascade
  add_foreign_key "commission_levels", "stores", on_delete: :cascade
  add_foreign_key "exchanges", "orders", column: "new_order_id"
  add_foreign_key "exchanges", "orders", column: "original_order_id"
  add_foreign_key "exchanges", "sellers"
  add_foreign_key "goals", "sellers", on_delete: :cascade
  add_foreign_key "goals", "stores"
  add_foreign_key "login_logs", "users", on_delete: :cascade
  add_foreign_key "order_items", "orders", on_delete: :cascade
  add_foreign_key "order_items", "products", on_delete: :cascade
  add_foreign_key "order_items", "stores"
  add_foreign_key "orders", "sellers", on_delete: :cascade
  add_foreign_key "orders", "stores"
  add_foreign_key "products", "categories", on_delete: :cascade
  add_foreign_key "queue_items", "companies", on_delete: :cascade
  add_foreign_key "queue_items", "sellers"
  add_foreign_key "queue_items", "stores"
  add_foreign_key "returns", "orders", column: "original_order_id"
  add_foreign_key "returns", "products"
  add_foreign_key "schedules", "sellers", on_delete: :cascade
  add_foreign_key "schedules", "shifts", on_delete: :cascade
  add_foreign_key "schedules", "stores", on_delete: :cascade
  add_foreign_key "sellers", "companies", on_delete: :cascade
  add_foreign_key "sellers", "stores", on_delete: :cascade
  add_foreign_key "sellers", "users", on_delete: :cascade
  add_foreign_key "shifts", "stores", on_delete: :cascade
  add_foreign_key "stores", "companies", on_delete: :cascade
end
