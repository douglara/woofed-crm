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

ActiveRecord::Schema.define(version: 2023_06_20_191827) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.datetime "due"
    t.boolean "done", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "apps", force: :cascade do |t|
    t.bigint "account_id"
    t.string "name"
    t.string "kind"
    t.boolean "active", default: false, null: false
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_apps_on_account_id"
  end

  create_table "apps_chatwoots", force: :cascade do |t|
    t.bigint "account_id"
    t.string "name"
    t.boolean "active", default: false, null: false
    t.string "status", default: "inactive", null: false
    t.string "embedding_token", default: "", null: false
    t.integer "chatwoot_account_id", null: false
    t.string "chatwoot_endpoint_url", default: "", null: false
    t.string "chatwoot_user_token", default: "", null: false
    t.integer "chatwoot_dashboard_app_id", null: false
    t.integer "chatwoot_webhook_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_apps_chatwoots_on_account_id"
  end

  create_table "apps_wpp_connects", force: :cascade do |t|
    t.bigint "account_id"
    t.string "name"
    t.boolean "active", default: false, null: false
    t.string "session", default: "", null: false
    t.string "token", default: "", null: false
    t.string "endpoint_url", default: "", null: false
    t.string "secretkey", default: "", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "status", default: "inactive", null: false
    t.index ["account_id"], name: "index_apps_wpp_connects_on_account_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "full_name", default: "", null: false
    t.string "phone", default: "", null: false
    t.string "email", default: "", null: false
    t.jsonb "custom_attributes", default: {}
    t.jsonb "additional_attributes", default: {}
    t.string "app_type"
    t.bigint "app_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_contacts_on_account_id"
    t.index ["app_type", "app_id"], name: "index_contacts_on_app"
  end

  create_table "contacts_deals", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "contact_id"
    t.bigint "deal_id"
    t.boolean "main", default: true, null: false
    t.index ["account_id"], name: "index_contacts_deals_on_account_id"
    t.index ["contact_id", "deal_id"], name: "contact_deal_index", unique: true
    t.index ["contact_id"], name: "index_contacts_deals_on_contact_id"
    t.index ["deal_id"], name: "index_contacts_deals_on_deal_id"
  end

  create_table "custom_attribute_definitions", force: :cascade do |t|
    t.integer "attribute_model", default: 0
    t.string "attribute_key"
    t.string "attribute_display_name"
    t.text "attribute_description"
    t.bigint "account_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_custom_attribute_definitions_on_account_id"
    t.index ["attribute_key", "attribute_model"], name: "attribute_key_model_index", unique: true
  end

  create_table "deals", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "status", default: "open", null: false
    t.bigint "account_id", null: false
    t.bigint "stage_id", null: false
    t.bigint "contact_id", null: false
    t.jsonb "custom_attributes", default: {}
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_deals_on_account_id"
    t.index ["contact_id"], name: "index_deals_on_contact_id"
    t.index ["stage_id"], name: "index_deals_on_stage_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "deal_id"
    t.bigint "contact_id"
    t.bigint "account_id", null: false
    t.string "app_type"
    t.bigint "app_id"
    t.string "kind", default: "note", null: false
    t.datetime "due"
    t.boolean "done"
    t.datetime "done_at"
    t.boolean "from_me"
    t.integer "status"
    t.jsonb "custom_attributes", default: {}
    t.jsonb "additional_attributes", default: {}
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_events_on_account_id"
    t.index ["app_type", "app_id"], name: "index_events_on_app"
    t.index ["contact_id"], name: "index_events_on_contact_id"
    t.index ["deal_id"], name: "index_events_on_deal_id"
  end

  create_table "flow_items", force: :cascade do |t|
    t.bigint "deal_id"
    t.bigint "contact_id", null: false
    t.string "kind_type"
    t.bigint "kind_id"
    t.jsonb "item"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["contact_id"], name: "index_flow_items_on_contact_id"
    t.index ["deal_id"], name: "index_flow_items_on_deal_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "state"
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "notes", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "pipelines", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", default: "", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_pipelines_on_account_id"
  end

  create_table "stages", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.bigint "account_id", null: false
    t.bigint "pipeline_id", null: false
    t.integer "order", default: 1, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_stages_on_account_id"
    t.index ["pipeline_id"], name: "index_stages_on_pipeline_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "full_name", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.bigint "account_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "webhooks", force: :cascade do |t|
    t.bigint "account_id"
    t.string "url", default: "", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_webhooks_on_account_id"
  end

  create_table "wp_connects", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.boolean "enabled", default: false, null: false
    t.string "secretkey", default: "", null: false
    t.string "endpoint_url", default: "", null: false
    t.string "session", default: "", null: false
    t.string "token", default: "", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "deals", "contacts"
  add_foreign_key "deals", "stages"
  add_foreign_key "events", "accounts"
  add_foreign_key "flow_items", "contacts"
  add_foreign_key "flow_items", "deals"
  add_foreign_key "stages", "pipelines"
  add_foreign_key "users", "accounts"
end
