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

ActiveRecord::Schema[8.1].define(version: 2026_10_24_200920) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_db_files", force: :cascade do |t|
    t.string "ref", null: false
    t.binary "data", null: false
    t.datetime "created_at", null: false
    t.index ["ref"], name: "index_active_storage_db_files_on_ref", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "change_requests", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "doc_number", null: false
    t.text "description", null: false
    t.integer "extra_rounds", default: 1, null: false
    t.integer "quote_hkd"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doc_number"], name: "index_change_requests_on_doc_number", unique: true
    t.index ["project_id"], name: "index_change_requests_on_project_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_clients_on_code", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "name", null: false
    t.integer "phase", default: 0, null: false
    t.integer "max_uat_rounds", default: 3, null: false
    t.date "maintenance_start_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_projects_on_client_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sign_offs", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "uat_round_id", null: false
    t.bigint "signed_by_id", null: false
    t.string "signer_name", null: false
    t.datetime "signed_at", null: false
    t.string "doc_number", null: false
    t.text "payload_json", null: false
    t.string "digest", null: false
    t.string "prev_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["digest"], name: "index_sign_offs_on_digest", unique: true
    t.index ["doc_number"], name: "index_sign_offs_on_doc_number", unique: true
    t.index ["project_id"], name: "index_sign_offs_on_project_id"
    t.index ["signed_by_id"], name: "index_sign_offs_on_signed_by_id"
    t.index ["uat_round_id"], name: "index_sign_offs_on_uat_round_id", unique: true
  end

  create_table "test_cases", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "code", null: false
    t.string "title", null: false
    t.text "steps"
    t.text "expected"
    t.integer "source", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "code"], name: "index_test_cases_on_project_id_and_code", unique: true
    t.index ["project_id"], name: "index_test_cases_on_project_id"
  end

  create_table "test_results", force: :cascade do |t|
    t.bigint "uat_round_id", null: false
    t.bigint "test_case_id", null: false
    t.integer "status", default: 0, null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["test_case_id"], name: "index_test_results_on_test_case_id"
    t.index ["uat_round_id", "test_case_id"], name: "index_test_results_on_uat_round_id_and_test_case_id", unique: true
    t.index ["uat_round_id"], name: "index_test_results_on_uat_round_id"
  end

  create_table "ticket_logs", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "user_id", null: false
    t.date "logged_on", null: false
    t.integer "minutes", default: 0, null: false
    t.text "note", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["logged_on"], name: "index_ticket_logs_on_logged_on"
    t.index ["ticket_id"], name: "index_ticket_logs_on_ticket_id"
    t.index ["user_id"], name: "index_ticket_logs_on_user_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "opened_by_id", null: false
    t.string "doc_number", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.integer "priority", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doc_number"], name: "index_tickets_on_doc_number", unique: true
    t.index ["opened_by_id"], name: "index_tickets_on_opened_by_id"
    t.index ["project_id"], name: "index_tickets_on_project_id"
    t.index ["status"], name: "index_tickets_on_status"
  end

  create_table "uat_rounds", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.integer "number", null: false
    t.integer "status", default: 0, null: false
    t.datetime "opened_at", null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "ai_summary"
    t.datetime "ai_summarised_at"
    t.index ["project_id", "number"], name: "index_uat_rounds_on_project_id_and_number", unique: true
    t.index ["project_id"], name: "index_uat_rounds_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 1, null: false
    t.bigint "client_id"
    t.index ["client_id"], name: "index_users_on_client_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "change_requests", "projects"
  add_foreign_key "projects", "clients"
  add_foreign_key "sessions", "users"
  add_foreign_key "sign_offs", "projects"
  add_foreign_key "sign_offs", "uat_rounds"
  add_foreign_key "sign_offs", "users", column: "signed_by_id"
  add_foreign_key "test_cases", "projects"
  add_foreign_key "test_results", "test_cases"
  add_foreign_key "test_results", "uat_rounds"
  add_foreign_key "ticket_logs", "tickets"
  add_foreign_key "ticket_logs", "users"
  add_foreign_key "tickets", "projects"
  add_foreign_key "tickets", "users", column: "opened_by_id"
  add_foreign_key "uat_rounds", "projects"
  add_foreign_key "users", "clients"
end
