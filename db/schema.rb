# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180221174932) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "hstore"
  enable_extension "pgcrypto"

  create_table "attachments", force: :cascade do |t|
    t.text     "description"
    t.datetime "created_at"
    t.integer  "user_id"
    t.decimal  "latitude",             precision: 15, scale: 12
    t.decimal  "longitude",            precision: 15, scale: 12
    t.string   "key"
    t.boolean  "public"
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.string   "mime_type"
    t.text     "url"
    t.text     "tags",                                           default: [],              array: true
    t.json     "metadata",                                       default: {}
    t.string   "status",                                                      null: false
    t.text     "source_url"
    t.integer  "parent_attachment_id"
  end

  add_index "attachments", ["attachable_id", "attachable_type"], name: "index_attachments_on_attachable_id_and_attachable_type", using: :btree
  add_index "attachments", ["attachable_type", "attachable_id"], name: "index_attachments_on_attachable_type_and_attachable_id", using: :btree
  add_index "attachments", ["key"], name: "index_attachments_on_key", using: :btree
  add_index "attachments", ["parent_attachment_id"], name: "index_attachments_on_parent_attachment_id", using: :btree
  add_index "attachments", ["status"], name: "index_attachments_on_status", using: :btree
  add_index "attachments", ["tags"], name: "index_attachments_on_tags", using: :gin
  add_index "attachments", ["user_id"], name: "index_attachments_on_user_id", using: :btree

  create_table "categories", force: :cascade do |t|
    t.string   "name",         null: false
    t.integer  "company_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "abbreviation"
    t.decimal  "base_price"
    t.integer  "capacity"
  end

  add_index "categories", ["company_id"], name: "index_categories_on_company_id", using: :btree

  create_table "categories_markets", id: false, force: :cascade do |t|
    t.integer "category_id", null: false
    t.integer "market_id",   null: false
  end

  add_index "categories_markets", ["category_id", "market_id"], name: "index_categories_markets_on_category_id_and_market_id", unique: true, using: :btree
  add_index "categories_markets", ["market_id", "category_id"], name: "index_categories_markets_on_market_id_and_category_id", unique: true, using: :btree

  create_table "categories_providers", id: false, force: :cascade do |t|
    t.integer "category_id", null: false
    t.integer "provider_id", null: false
  end

  add_index "categories_providers", ["category_id", "provider_id"], name: "index_categories_providers_on_category_id_and_provider_id", using: :btree
  add_index "categories_providers", ["category_id", "provider_id"], name: "index_categories_providers_on_unique_category_provider", unique: true, using: :btree
  add_index "categories_providers", ["provider_id", "category_id"], name: "index_categories_providers_on_provider_id_and_category_id", using: :btree

  create_table "checkins", force: :cascade do |t|
    t.integer  "locatable_id"
    t.string   "locatable_type"
    t.decimal  "latitude",                                                precision: 15, scale: 12, null: false
    t.decimal  "longitude",                                               precision: 15, scale: 12, null: false
    t.datetime "checkin_at",                                                                        null: false
    t.string   "reason"
    t.geometry "geom",           limit: {:srid=>4326, :type=>"geometry"}
    t.decimal  "heading"
  end

  add_index "checkins", ["locatable_id", "locatable_type"], name: "index_checkins_on_locatable_id_and_locatable_type", using: :btree
  add_index "checkins", ["locatable_type", "locatable_id"], name: "index_checkins_on_locatable_type_and_locatable_id", using: :btree

  create_table "comments", force: :cascade do |t|
    t.text     "body"
    t.datetime "created_at"
    t.integer  "user_id"
    t.decimal  "latitude",         precision: 15, scale: 12
    t.decimal  "longitude",        precision: 15, scale: 12
    t.integer  "commentable_id"
    t.string   "commentable_type"
  end

  add_index "comments", ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "companies", force: :cascade do |t|
    t.integer "user_id"
    t.string  "name"
    t.json    "config",                default: {}, null: false
    t.string  "stripe_customer_id"
    t.string  "stripe_credit_card_id"
  end

  add_index "companies", ["user_id"], name: "index_companies_on_user_id", using: :btree

  create_table "contacts", force: :cascade do |t|
    t.integer  "contactable_id"
    t.string   "contactable_type"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "email"
    t.string   "phone"
    t.string   "fax"
    t.string   "time_zone_id"
    t.decimal  "latitude",                                                  precision: 15, scale: 12
    t.decimal  "longitude",                                                 precision: 15, scale: 12
    t.string   "mobile"
    t.string   "name"
    t.geometry "geom",             limit: {:srid=>4326, :type=>"geometry"}
    t.date     "dob"
    t.string   "website"
    t.text     "description"
    t.json     "data"
  end

  add_index "contacts", ["contactable_id", "contactable_type"], name: "index_contacts_on_contactable_id_and_contactable_type", unique: true, using: :btree
  add_index "contacts", ["dob"], name: "index_contacts_on_dob", using: :btree
  add_index "contacts", ["geom"], name: "index_contacts_on_geom", using: :gist
  add_index "contacts", ["name"], name: "index_contacts_on_name", using: :btree
  add_index "contacts", ["time_zone_id"], name: "index_contacts_on_time_zone_id", using: :btree

  create_table "customers", force: :cascade do |t|
    t.integer "company_id"
    t.integer "user_id"
    t.string  "name"
    t.json    "config",          default: {}, null: false
    t.string  "customer_number"
  end

  add_index "customers", ["company_id", "customer_number"], name: "index_customers_on_company_id_and_customer_number", using: :btree
  add_index "customers", ["company_id"], name: "index_customers_on_company_id", using: :btree
  add_index "customers", ["name"], name: "index_customers_on_name", using: :btree
  add_index "customers", ["user_id", "company_id"], name: "index_customers_on_user_id_and_company_id", unique: true, using: :btree

  create_table "delivered_products_work_orders", id: false, force: :cascade do |t|
    t.integer "product_id",    null: false
    t.integer "work_order_id", null: false
  end

  add_index "delivered_products_work_orders", ["product_id", "work_order_id"], name: "index_delivered_products_work_orders_on_wo_and_product_id", using: :btree
  add_index "delivered_products_work_orders", ["work_order_id", "product_id"], name: "index_delivered_products_work_orders_on_product_and_wo_id", using: :btree

  create_table "devices", force: :cascade do |t|
    t.integer "user_id"
    t.string  "apns_device_id"
    t.string  "gcm_registration_id"
    t.string  "bundle_id"
  end

  add_index "devices", ["apns_device_id"], name: "index_devices_on_apns_device_id", using: :btree
  add_index "devices", ["gcm_registration_id"], name: "index_devices_on_gcm_registration_id", using: :btree
  add_index "devices", ["user_id", "apns_device_id"], name: "index_devices_on_user_id_and_apns_device_id", unique: true, using: :btree
  add_index "devices", ["user_id", "gcm_registration_id"], name: "index_devices_on_user_id_and_gcm_registration_id", unique: true, using: :btree
  add_index "devices", ["user_id"], name: "index_devices_on_user_id", using: :btree

  create_table "dispatcher_origin_assignments", force: :cascade do |t|
    t.integer  "origin_id",          null: false
    t.integer  "dispatcher_id",      null: false
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "scheduled_start_at"
    t.datetime "scheduled_end_at"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "canceled_at"
  end

  add_index "dispatcher_origin_assignments", ["dispatcher_id"], name: "index_dispatcher_origin_assignments_on_dispatcher_id", using: :btree
  add_index "dispatcher_origin_assignments", ["end_date"], name: "index_dispatcher_origin_assignments_on_end_date", using: :btree
  add_index "dispatcher_origin_assignments", ["origin_id"], name: "index_dispatcher_origin_assignments_on_origin_id", using: :btree
  add_index "dispatcher_origin_assignments", ["scheduled_end_at"], name: "index_dispatcher_origin_assignments_on_scheduled_end_at", using: :btree
  add_index "dispatcher_origin_assignments", ["scheduled_start_at"], name: "index_dispatcher_origin_assignments_on_scheduled_start_at", using: :btree
  add_index "dispatcher_origin_assignments", ["start_date"], name: "index_dispatcher_origin_assignments_on_start_date", using: :btree

  create_table "dispatchers", force: :cascade do |t|
    t.integer "company_id"
    t.integer "user_id"
  end

  add_index "dispatchers", ["company_id"], name: "index_dispatchers_on_company_id", using: :btree
  add_index "dispatchers", ["user_id", "company_id"], name: "index_dispatchers_on_user_id_and_company_id", unique: true, using: :btree

  create_table "expenses", force: :cascade do |t|
    t.integer  "expensable_id"
    t.string   "expensable_type"
    t.string   "status",          null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",         null: false
    t.decimal  "amount"
    t.datetime "incurred_at"
    t.text     "description"
  end

  add_index "expenses", ["expensable_id", "expensable_type"], name: "index_expenses_on_expensable_id_and_expensable_type", using: :btree
  add_index "expenses", ["status"], name: "index_expenses_on_status", using: :btree
  add_index "expenses", ["user_id"], name: "index_expenses_on_user_id", using: :btree

  create_table "invitations", force: :cascade do |t|
    t.integer  "sender_id"
    t.integer  "invitable_id"
    t.string   "invitable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "token",          null: false
    t.datetime "accepted_at"
    t.datetime "expires_at"
  end

  add_index "invitations", ["accepted_at"], name: "index_invitations_on_accepted_at", using: :btree
  add_index "invitations", ["expires_at"], name: "index_invitations_on_expires_at", using: :btree
  add_index "invitations", ["invitable_id", "invitable_type"], name: "index_invitations_on_invitable_id_and_invitable_type", using: :btree
  add_index "invitations", ["invitable_type", "invitable_id"], name: "index_invitations_on_invitable_type_and_invitable_id", using: :btree
  add_index "invitations", ["sender_id"], name: "index_invitations_on_sender_id", using: :btree
  add_index "invitations", ["token"], name: "index_invitations_on_token", unique: true, using: :btree

  create_table "job_products", force: :cascade do |t|
    t.integer  "job_id",                         null: false
    t.integer  "product_id",                     null: false
    t.float    "initial_quantity", default: 0.0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "price"
  end

  add_index "job_products", ["initial_quantity"], name: "index_job_products_on_initial_quantity", using: :btree
  add_index "job_products", ["job_id", "product_id"], name: "index_job_products_on_job_id_and_product_id", unique: true, using: :btree
  add_index "job_products", ["job_id"], name: "index_job_products_on_job_id", using: :btree
  add_index "job_products", ["product_id"], name: "index_job_products_on_product_id", using: :btree

  create_table "jobs", force: :cascade do |t|
    t.integer  "company_id"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "name"
    t.integer  "customer_id"
    t.string   "status"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "canceled_at"
    t.integer  "duration"
    t.integer  "job_duration"
    t.decimal  "quoted_price_per_sq_ft"
    t.decimal  "total_sq_ft"
    t.decimal  "contract_revenue"
    t.boolean  "wizard_mode",            default: true, null: false
    t.string   "type",                                  null: false
  end

  add_index "jobs", ["company_id"], name: "index_jobs_on_company_id", using: :btree
  add_index "jobs", ["status"], name: "index_jobs_on_status", using: :btree
  add_index "jobs", ["type"], name: "index_jobs_on_type", using: :btree

  create_table "jobs_work_orders", id: false, force: :cascade do |t|
    t.integer "job_id",        null: false
    t.integer "work_order_id", null: false
  end

  create_table "jwt_tokens", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "token",       null: false
    t.integer  "company_id"
    t.integer  "provider_id"
    t.integer  "user_id"
  end

  add_index "jwt_tokens", ["company_id"], name: "index_jwt_tokens_on_company_id", using: :btree
  add_index "jwt_tokens", ["provider_id"], name: "index_jwt_tokens_on_provider_id", using: :btree
  add_index "jwt_tokens", ["token"], name: "index_jwt_tokens_on_token", using: :btree
  add_index "jwt_tokens", ["user_id"], name: "index_jwt_tokens_on_user_id", using: :btree

  create_table "loaded_products_routes", id: false, force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "route_id",   null: false
  end

  add_index "loaded_products_routes", ["route_id", "product_id"], name: "index_loaded_products_routes_on_route_id_and_product_id", using: :btree

  create_table "markets", force: :cascade do |t|
    t.integer  "company_id"
    t.string   "name"
    t.string   "google_place_id"
    t.string   "time_zone_id"
    t.geometry "geom",            limit: {:srid=>4326, :type=>"geometry"}
  end

  add_index "markets", ["company_id", "google_place_id"], name: "index_markets_on_company_id_and_google_place_id", unique: true, using: :btree
  add_index "markets", ["company_id"], name: "index_markets_on_company_id", using: :btree
  add_index "markets", ["geom"], name: "index_markets_on_geom", using: :gist

  create_table "messages", force: :cascade do |t|
    t.integer  "recipient_id"
    t.integer  "sender_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "media_url"
  end

  add_index "messages", ["recipient_id"], name: "index_messages_on_recipient_id", using: :btree
  add_index "messages", ["sender_id"], name: "index_messages_on_sender_id", using: :btree

  create_table "notifications", force: :cascade do |t|
    t.integer  "notifiable_id"
    t.string   "notifiable_type"
    t.integer  "recipient_id"
    t.string   "type"
    t.string   "slug"
    t.datetime "delivered_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "suppressed_at"
  end

  add_index "notifications", ["delivered_at"], name: "index_notifications_on_delivered_at", using: :btree
  add_index "notifications", ["notifiable_id", "notifiable_type"], name: "index_notifications_on_notifiable_id_and_notifiable_type", using: :btree
  add_index "notifications", ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id", using: :btree
  add_index "notifications", ["recipient_id", "type", "slug"], name: "index_notifications_on_recipient_id_and_type_and_slug", unique: true, using: :btree

  create_table "ordered_products_work_orders", id: false, force: :cascade do |t|
    t.integer "product_id",    null: false
    t.integer "work_order_id", null: false
  end

  add_index "ordered_products_work_orders", ["product_id", "work_order_id"], name: "index_ordered_products_work_orders_on_work_order_and_product_id", using: :btree
  add_index "ordered_products_work_orders", ["work_order_id", "product_id"], name: "index_ordered_products_work_orders_on_product_and_work_order_id", using: :btree

  create_table "origins", force: :cascade do |t|
    t.integer "market_id"
    t.decimal "latitude",         precision: 15, scale: 12
    t.decimal "longitude",        precision: 15, scale: 12
    t.string  "warehouse_number"
  end

  add_index "origins", ["market_id", "warehouse_number"], name: "index_origins_on_market_id_and_warehouse_number", using: :btree
  add_index "origins", ["market_id"], name: "index_origins_on_market_id", using: :btree

  create_table "payment_methods", force: :cascade do |t|
    t.string  "type",                  null: false
    t.integer "user_id",               null: false
    t.string  "brand"
    t.string  "last4"
    t.string  "stripe_token"
    t.string  "stripe_credit_card_id"
  end

  add_index "payment_methods", ["type"], name: "index_payment_methods_on_type", using: :btree
  add_index "payment_methods", ["user_id"], name: "index_payment_methods_on_user_id", using: :btree

  create_table "products", force: :cascade do |t|
    t.string  "gtin"
    t.integer "company_id"
    t.text    "barcode_uri"
    t.json    "data",        default: {}, null: false
    t.string  "tier"
    t.integer "product_id"
  end

  add_index "products", ["company_id", "gtin"], name: "index_products_on_company_id_and_gtin", unique: true, using: :btree
  add_index "products", ["company_id"], name: "index_products_on_company_id", using: :btree
  add_index "products", ["gtin"], name: "index_products_on_gtin", using: :btree
  add_index "products", ["product_id"], name: "index_products_on_product_id", using: :btree
  add_index "products", ["tier"], name: "index_products_on_tier", using: :btree

  create_table "provider_origin_assignments", force: :cascade do |t|
    t.integer  "origin_id",          null: false
    t.integer  "provider_id",        null: false
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "scheduled_start_at"
    t.datetime "scheduled_end_at"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.string   "status"
    t.datetime "canceled_at"
    t.integer  "duration"
  end

  add_index "provider_origin_assignments", ["end_date"], name: "index_provider_origin_assignments_on_end_date", using: :btree
  add_index "provider_origin_assignments", ["origin_id"], name: "index_provider_origin_assignments_on_origin_id", using: :btree
  add_index "provider_origin_assignments", ["provider_id"], name: "index_provider_origin_assignments_on_provider_id", using: :btree
  add_index "provider_origin_assignments", ["scheduled_end_at"], name: "index_provider_origin_assignments_on_scheduled_end_at", using: :btree
  add_index "provider_origin_assignments", ["scheduled_start_at"], name: "index_provider_origin_assignments_on_scheduled_start_at", using: :btree
  add_index "provider_origin_assignments", ["start_date"], name: "index_provider_origin_assignments_on_start_date", using: :btree
  add_index "provider_origin_assignments", ["status"], name: "index_provider_origin_assignments_on_status", using: :btree

  create_table "providers", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "user_id"
    t.boolean  "publicly_available",                                                                        default: false
    t.string   "provider_number"
    t.geometry "last_checkin_geom",      limit: {:srid=>4326, :type=>"geometry"}
    t.datetime "last_checkin_at"
    t.boolean  "available",                                                                                 default: false
    t.decimal  "last_checkin_latitude",                                           precision: 15, scale: 12
    t.decimal  "last_checkin_longitude",                                          precision: 15, scale: 12
    t.decimal  "last_checkin_heading",                                            precision: 15, scale: 12
  end

  add_index "providers", ["available"], name: "index_providers_on_available", using: :btree
  add_index "providers", ["company_id", "provider_number"], name: "index_providers_on_company_id_and_provider_number", using: :btree
  add_index "providers", ["company_id"], name: "index_providers_on_company_id", using: :btree
  add_index "providers", ["last_checkin_at"], name: "index_providers_on_last_checkin_at", using: :btree
  add_index "providers", ["last_checkin_geom"], name: "index_providers_on_last_checkin_geom", using: :gist
  add_index "providers", ["publicly_available"], name: "index_providers_on_publicly_available", using: :btree
  add_index "providers", ["user_id", "company_id"], name: "index_providers_on_user_id_and_company_id", unique: true, using: :btree

  create_table "rejected_products_work_orders", id: false, force: :cascade do |t|
    t.integer "product_id",    null: false
    t.integer "work_order_id", null: false
  end

  add_index "rejected_products_work_orders", ["product_id", "work_order_id"], name: "index_reject_products_work_orders_on_work_order_and_product_id", using: :btree
  add_index "rejected_products_work_orders", ["work_order_id", "product_id"], name: "index_reject_products_work_orders_on_product_and_work_order_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "route_legs", force: :cascade do |t|
    t.integer  "route_id"
    t.datetime "actual_start_at"
    t.datetime "actual_end_at"
    t.float    "actual_traffic"
    t.datetime "estimated_start_at"
    t.datetime "estimated_end_at"
    t.datetime "estimated_end_at_on_start"
    t.float    "estimated_traffic"
  end

  add_index "route_legs", ["route_id"], name: "index_route_legs_on_route_id", using: :btree

  create_table "routes", force: :cascade do |t|
    t.integer  "provider_origin_assignment_id"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.string   "status"
    t.date     "date"
    t.string   "name"
    t.string   "identifier"
    t.integer  "dispatcher_origin_assignment_id"
    t.datetime "scheduled_start_at"
    t.datetime "scheduled_end_at"
    t.datetime "loading_started_at"
    t.datetime "loading_ended_at"
    t.datetime "unloading_started_at"
    t.datetime "unloading_ended_at"
    t.integer  "duration"
    t.integer  "loading_duration"
    t.integer  "unloading_duration"
    t.string   "fastest_here_api_route_id"
    t.string   "shortest_here_api_route_id"
    t.integer  "company_id",                      null: false
  end

  add_index "routes", ["date"], name: "index_routes_on_date", using: :btree
  add_index "routes", ["dispatcher_origin_assignment_id"], name: "index_routes_on_dispatcher_origin_assignment_id", using: :btree
  add_index "routes", ["ended_at"], name: "index_routes_on_ended_at", using: :btree
  add_index "routes", ["identifier"], name: "index_routes_on_identifier", using: :btree
  add_index "routes", ["provider_origin_assignment_id"], name: "index_routes_on_provider_origin_assignment_id", using: :btree
  add_index "routes", ["scheduled_end_at"], name: "index_routes_on_scheduled_end_at", using: :btree
  add_index "routes", ["scheduled_start_at"], name: "index_routes_on_scheduled_start_at", using: :btree
  add_index "routes", ["started_at"], name: "index_routes_on_started_at", using: :btree
  add_index "routes", ["status"], name: "index_routes_on_status", using: :btree

  create_table "shortened_urls", force: :cascade do |t|
    t.integer  "owner_id"
    t.string   "owner_type", limit: 20
    t.string   "url",                               null: false
    t.string   "unique_key", limit: 10,             null: false
    t.integer  "use_count",             default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shortened_urls", ["owner_id", "owner_type"], name: "index_shortened_urls_on_owner_id_and_owner_type", using: :btree
  add_index "shortened_urls", ["unique_key"], name: "index_shortened_urls_on_unique_key", unique: true, using: :btree
  add_index "shortened_urls", ["url"], name: "index_shortened_urls_on_url", using: :btree

  create_table "tasks", force: :cascade do |t|
    t.integer  "task_id"
    t.integer  "company_id"
    t.integer  "category_id"
    t.integer  "user_id"
    t.integer  "provider_id"
    t.integer  "job_id"
    t.integer  "work_order_id"
    t.text     "name",          null: false
    t.text     "description"
    t.datetime "due_at"
    t.datetime "canceled_at"
    t.datetime "completed_at"
    t.datetime "declined_at"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tasks", ["category_id"], name: "index_tasks_on_category_id", using: :btree
  add_index "tasks", ["company_id"], name: "index_tasks_on_company_id", using: :btree
  add_index "tasks", ["due_at"], name: "index_tasks_on_due_at", using: :btree
  add_index "tasks", ["job_id"], name: "index_tasks_on_job_id", using: :btree
  add_index "tasks", ["provider_id"], name: "index_tasks_on_provider_id", using: :btree
  add_index "tasks", ["status"], name: "index_tasks_on_status", using: :btree
  add_index "tasks", ["task_id", "user_id", "provider_id"], name: "index_tasks_on_task_id_and_user_id_and_provider_id", unique: true, using: :btree
  add_index "tasks", ["task_id"], name: "index_tasks_on_task_id", using: :btree
  add_index "tasks", ["user_id"], name: "index_tasks_on_user_id", using: :btree
  add_index "tasks", ["work_order_id"], name: "index_tasks_on_work_order_id", using: :btree

  create_table "tokens", force: :cascade do |t|
    t.string   "token",                           null: false
    t.string   "token_hash",                      null: false
    t.integer  "authenticable_id",                null: false
    t.string   "authenticable_type"
    t.string   "type"
    t.json     "metadata",           default: {}
    t.datetime "expires_at"
    t.datetime "invalidated_at"
    t.datetime "last_active_at"
  end

  add_index "tokens", ["authenticable_id", "authenticable_type"], name: "index_tokens_on_authenticable_id_and_authenticable_type", using: :btree
  add_index "tokens", ["authenticable_type", "authenticable_id"], name: "index_tokens_on_authenticable_type_and_authenticable_id", using: :btree
  add_index "tokens", ["invalidated_at"], name: "index_tokens_on_invalidated_at", using: :btree
  add_index "tokens", ["last_active_at"], name: "index_tokens_on_last_active_at", using: :btree
  add_index "tokens", ["token"], name: "index_tokens_on_token", unique: true, using: :btree
  add_index "tokens", ["type"], name: "index_tokens_on_type", using: :btree

  create_table "user_order_shares", force: :cascade do |t|
    t.string   "fb_user_id"
    t.integer  "work_order_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "user_order_shares", ["fb_user_id"], name: "index_user_order_shares_on_fb_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                                                                                         default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                                                                 default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",                                                                               default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "name"
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "invitations_count",                                                                             default: 0
    t.string   "password_digest"
    t.json     "preferences",                                                                                   default: {}
    t.string   "stripe_customer_id"
    t.decimal  "last_checkin_latitude",                                               precision: 15, scale: 12
    t.decimal  "last_checkin_longitude",                                              precision: 15, scale: 12
    t.decimal  "last_checkin_heading",                                                precision: 15, scale: 12
    t.datetime "last_checkin_at"
    t.geometry "last_checkin_geom",          limit: {:srid=>4326, :type=>"geometry"}
    t.string   "fb_user_id"
    t.string   "fb_access_token"
    t.datetime "fb_access_token_expires_at"
    t.string   "prvd_user_id"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["fb_user_id"], name: "index_users_on_fb_user_id", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["last_checkin_at"], name: "index_users_on_last_checkin_at", using: :btree
  add_index "users", ["last_checkin_geom"], name: "index_users_on_last_checkin_geom", using: :gist
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "wallets", force: :cascade do |t|
    t.integer "user_id",   null: false
    t.string  "type",      null: false
    t.string  "address",   null: false
    t.string  "wallet_id"
  end

  add_index "wallets", ["type"], name: "index_wallets_on_type", using: :btree
  add_index "wallets", ["user_id"], name: "index_wallets_on_user_id", using: :btree

  create_table "work_order_products", force: :cascade do |t|
    t.integer  "work_order_id",                null: false
    t.integer  "job_product_id",               null: false
    t.decimal  "price"
    t.float    "quantity",       default: 0.0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "work_order_products", ["job_product_id"], name: "index_work_order_products_on_job_product_id", using: :btree
  add_index "work_order_products", ["quantity"], name: "index_work_order_products_on_quantity", using: :btree
  add_index "work_order_products", ["work_order_id", "job_product_id"], name: "index_work_order_products_on_work_order_id_and_job_product_id", unique: true, using: :btree
  add_index "work_order_products", ["work_order_id"], name: "index_work_order_products_on_work_order_id", using: :btree

  create_table "work_order_providers", force: :cascade do |t|
    t.integer  "provider_id",        null: false
    t.integer  "work_order_id",      null: false
    t.datetime "confirmed_at"
    t.decimal  "hourly_rate"
    t.integer  "duration"
    t.integer  "estimated_duration"
    t.integer  "rating"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "arrived_at"
    t.datetime "abandoned_at"
    t.datetime "canceled_at"
    t.integer  "driving_duration"
    t.integer  "work_duration"
    t.integer  "waiting_duration"
    t.decimal  "flat_fee"
    t.decimal  "flat_fee_due"
    t.decimal  "hourly_rate_due"
    t.datetime "timed_out_at"
  end

  add_index "work_order_providers", ["provider_id", "work_order_id"], name: "index_work_order_providers_on_provider_id_and_work_order_id", unique: true, using: :btree
  add_index "work_order_providers", ["timed_out_at"], name: "index_work_order_providers_on_timed_out_at", using: :btree
  add_index "work_order_providers", ["work_order_id"], name: "index_work_order_providers_on_work_order_id", using: :btree

  create_table "work_orders", force: :cascade do |t|
    t.integer  "customer_id"
    t.integer  "company_id"
    t.text     "description"
    t.string   "status"
    t.integer  "estimated_duration"
    t.integer  "customer_rating"
    t.integer  "provider_rating"
    t.datetime "scheduled_start_at"
    t.datetime "scheduled_end_at"
    t.date     "preferred_scheduled_start_date"
    t.integer  "origin_id"
    t.integer  "route_leg_id"
    t.json     "config",                         default: {}, null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "arrived_at"
    t.datetime "abandoned_at"
    t.datetime "canceled_at"
    t.integer  "driving_duration"
    t.integer  "work_duration"
    t.integer  "waiting_duration"
    t.integer  "job_id"
    t.integer  "category_id"
    t.datetime "submitted_for_approval_at"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.integer  "review_duration"
    t.integer  "priority"
    t.datetime "due_at"
    t.integer  "user_id"
    t.integer  "user_rating"
    t.datetime "accepted_at"
    t.decimal  "estimated_distance"
    t.string   "eth_tx_hash"
    t.string   "eth_contract_address"
    t.decimal  "price"
  end

  add_index "work_orders", ["abandoned_at"], name: "index_work_orders_on_abandoned_at", using: :btree
  add_index "work_orders", ["category_id"], name: "index_work_orders_on_category_id", using: :btree
  add_index "work_orders", ["company_id", "scheduled_start_at", "scheduled_end_at"], name: "index_work_orders_on_company_id_and_start_at_and_end_at", using: :btree
  add_index "work_orders", ["customer_id"], name: "index_work_orders_on_customer_id", using: :btree
  add_index "work_orders", ["due_at"], name: "index_work_orders_on_due_at", using: :btree
  add_index "work_orders", ["origin_id"], name: "index_work_orders_on_origin_id", using: :btree
  add_index "work_orders", ["preferred_scheduled_start_date"], name: "index_work_orders_on_preferred_scheduled_start_date", using: :btree
  add_index "work_orders", ["priority"], name: "index_work_orders_on_priority", using: :btree
  add_index "work_orders", ["status"], name: "index_work_orders_on_status", using: :btree
  add_index "work_orders", ["user_id"], name: "index_work_orders_on_user_id", using: :btree

  add_foreign_key "attachments", "attachments", column: "parent_attachment_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "attachments", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "categories", "companies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "categories_markets", "categories", on_update: :cascade, on_delete: :nullify
  add_foreign_key "categories_markets", "markets", on_update: :cascade, on_delete: :nullify
  add_foreign_key "categories_providers", "categories", on_update: :cascade, on_delete: :cascade
  add_foreign_key "categories_providers", "providers", on_update: :cascade, on_delete: :cascade
  add_foreign_key "comments", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "companies", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "customers", "companies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "customers", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "delivered_products_work_orders", "products", on_update: :cascade, on_delete: :cascade
  add_foreign_key "delivered_products_work_orders", "work_orders", on_update: :cascade, on_delete: :cascade
  add_foreign_key "devices", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "dispatcher_origin_assignments", "dispatchers", on_update: :cascade, on_delete: :cascade
  add_foreign_key "dispatcher_origin_assignments", "origins", on_update: :cascade, on_delete: :cascade
  add_foreign_key "dispatchers", "companies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "dispatchers", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "invitations", "users", column: "sender_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "job_products", "jobs", on_update: :cascade, on_delete: :cascade
  add_foreign_key "job_products", "products", on_update: :cascade, on_delete: :cascade
  add_foreign_key "jobs", "companies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "jobs", "customers", on_update: :cascade, on_delete: :nullify
  add_foreign_key "jobs_work_orders", "jobs", on_update: :cascade, on_delete: :cascade
  add_foreign_key "jobs_work_orders", "work_orders", on_update: :cascade, on_delete: :cascade
  add_foreign_key "jwt_tokens", "companies"
  add_foreign_key "jwt_tokens", "providers"
  add_foreign_key "loaded_products_routes", "products", on_update: :cascade, on_delete: :cascade
  add_foreign_key "loaded_products_routes", "routes", on_update: :cascade, on_delete: :cascade
  add_foreign_key "markets", "companies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "messages", "users", column: "recipient_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "messages", "users", column: "sender_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "notifications", "users", column: "recipient_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ordered_products_work_orders", "products", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ordered_products_work_orders", "work_orders", on_update: :cascade, on_delete: :cascade
  add_foreign_key "origins", "markets", on_update: :cascade, on_delete: :cascade
  add_foreign_key "products", "companies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "provider_origin_assignments", "origins", name: "fk_providers_origin_assignments_origin_id"
  add_foreign_key "provider_origin_assignments", "origins", on_update: :cascade, on_delete: :cascade
  add_foreign_key "provider_origin_assignments", "providers", name: "fk_providers_origin_assignments_provider_id"
  add_foreign_key "provider_origin_assignments", "providers", on_update: :cascade, on_delete: :cascade
  add_foreign_key "providers", "companies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "providers", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "rejected_products_work_orders", "products", on_update: :cascade, on_delete: :cascade
  add_foreign_key "rejected_products_work_orders", "work_orders", on_update: :cascade, on_delete: :cascade
  add_foreign_key "route_legs", "routes", on_update: :cascade, on_delete: :cascade
  add_foreign_key "routes", "companies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "routes", "dispatcher_origin_assignments", on_update: :cascade, on_delete: :cascade
  add_foreign_key "routes", "provider_origin_assignments", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks", "categories", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks", "companies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks", "jobs", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks", "providers", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks", "tasks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks", "work_orders", on_update: :cascade, on_delete: :cascade
  add_foreign_key "users_roles", "roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "users_roles", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "wallets", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "work_order_products", "job_products", on_update: :cascade, on_delete: :cascade
  add_foreign_key "work_order_products", "work_orders", on_update: :cascade, on_delete: :cascade
  add_foreign_key "work_order_providers", "providers", on_update: :cascade, on_delete: :cascade
  add_foreign_key "work_order_providers", "work_orders", on_update: :cascade, on_delete: :cascade
  add_foreign_key "work_orders", "categories", on_update: :cascade, on_delete: :cascade
  add_foreign_key "work_orders", "companies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "work_orders", "customers", on_update: :cascade, on_delete: :cascade
  add_foreign_key "work_orders", "jobs", on_update: :cascade, on_delete: :nullify
  add_foreign_key "work_orders", "origins", on_update: :cascade, on_delete: :cascade
  add_foreign_key "work_orders", "route_legs", on_update: :cascade, on_delete: :cascade
end
