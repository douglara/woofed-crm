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

ActiveRecord::Schema[7.1].define(version: 2025_05_15_041032) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "accounts", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "site_url", default: "", null: false
    t.boolean "woofbot_auto_reply", default: false, null: false
    t.jsonb "ai_usage", default: {"limit"=>16666667, "tokens"=>0}, null: false
    t.string "segment", default: "other", null: false
    t.string "number_of_employees", default: "1-10", null: false
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "apps", force: :cascade do |t|
    t.string "name"
    t.string "kind"
    t.boolean "active", default: false, null: false
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "apps_ai_assistents", force: :cascade do |t|
    t.boolean "enabled", default: false, null: false
    t.string "api_key", default: "", null: false
    t.string "model", default: "gpt-4o", null: false
    t.boolean "auto_reply", default: false, null: false
    t.jsonb "usage", default: {"tokens"=>0}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "apps_chatwoots", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: false, null: false
    t.string "status", default: "inactive", null: false
    t.string "embedding_token", default: "", null: false
    t.integer "chatwoot_account_id", null: false
    t.string "chatwoot_endpoint_url", default: "", null: false
    t.string "chatwoot_user_token", default: "", null: false
    t.integer "chatwoot_dashboard_app_id", null: false
    t.integer "chatwoot_webhook_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "inboxes", default: [], null: false
  end

  create_table "apps_evolution_apis", force: :cascade do |t|
    t.string "connection_status", default: "disconnected", null: false
    t.boolean "active", default: true, null: false
    t.string "endpoint_url", default: "", null: false
    t.string "token", default: "", null: false
    t.string "phone", default: "", null: false
    t.string "name", default: "", null: false
    t.string "instance", default: "", null: false
    t.jsonb "additional_attributes", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "qrcode", default: "", null: false
  end

  create_table "attachments", force: :cascade do |t|
    t.string "attachable_type", null: false
    t.bigint "attachable_id", null: false
    t.integer "file_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attachable_type", "attachable_id"], name: "index_attachments_on_attachable"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "full_name", default: "", null: false
    t.string "phone", default: "", null: false
    t.string "email", default: "", null: false
    t.jsonb "custom_attributes", default: {}
    t.jsonb "additional_attributes", default: {}
    t.string "app_type"
    t.bigint "app_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "NULLIF((phone)::text, ''::text)", name: "index_contacts_on_phone", unique: true
    t.index "lower(NULLIF((email)::text, ''::text))", name: "index_contacts_on_lower_email", unique: true
    t.index ["app_type", "app_id"], name: "index_contacts_on_app"
  end

  create_table "custom_attribute_definitions", force: :cascade do |t|
    t.integer "attribute_model", default: 0
    t.string "attribute_key"
    t.string "attribute_display_name"
    t.text "attribute_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "deal_assignees", force: :cascade do |t|
    t.bigint "deal_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deal_id", "user_id"], name: "index_deal_assignees_on_deal_id_and_user_id", unique: true
    t.index ["deal_id"], name: "index_deal_assignees_on_deal_id"
    t.index ["user_id"], name: "index_deal_assignees_on_user_id"
  end

  create_table "deal_products", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "deal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "unit_amount_in_cents", default: 0, null: false
    t.string "product_identifier", default: "", null: false
    t.string "product_name", default: "", null: false
    t.bigint "total_amount_in_cents", default: 0, null: false
    t.bigint "quantity", default: 1, null: false
    t.index ["deal_id"], name: "index_deal_products_on_deal_id"
    t.index ["product_id"], name: "index_deal_products_on_product_id"
  end

  create_table "deals", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "status", default: "open", null: false
    t.bigint "stage_id", null: false
    t.bigint "contact_id", null: false
    t.jsonb "custom_attributes", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pipeline_id"
    t.integer "position", default: 1, null: false
    t.integer "created_by_id"
    t.bigint "total_deal_products_amount_in_cents", default: 0, null: false
    t.datetime "lost_at"
    t.datetime "won_at"
    t.index ["contact_id"], name: "index_deals_on_contact_id"
    t.index ["created_by_id"], name: "index_deals_on_created_by_id"
    t.index ["pipeline_id"], name: "index_deals_on_pipeline_id"
    t.index ["stage_id"], name: "index_deals_on_stage_id"
  end

  create_table "embedding_documments", force: :cascade do |t|
    t.string "source_type"
    t.bigint "source_id"
    t.string "source_reference"
    t.integer "status", default: 0
    t.text "content"
    t.vector "embedding", limit: 1536
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_type", "source_id"], name: "index_embedding_documments_on_source"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "deal_id"
    t.bigint "contact_id"
    t.string "app_type"
    t.bigint "app_id"
    t.string "kind", null: false
    t.datetime "scheduled_at", precision: nil
    t.datetime "done_at", precision: nil
    t.boolean "from_me"
    t.integer "status"
    t.jsonb "custom_attributes", default: {}
    t.jsonb "additional_attributes", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title", default: "", null: false
    t.boolean "auto_done", default: false
    t.index ["app_type", "app_id"], name: "index_events_on_app"
    t.index ["contact_id"], name: "index_events_on_contact_id"
    t.index ["deal_id"], name: "index_events_on_deal_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at", precision: nil
    t.datetime "discarded_at", precision: nil
    t.datetime "finished_at", precision: nil
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at", precision: nil
    t.datetime "performed_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at", precision: nil
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at", precision: nil
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "installations", id: :string, force: :cascade do |t|
    t.string "key1", default: "", null: false
    t.string "key2", default: "", null: false
    t.string "token", default: "", null: false
    t.integer "status", default: 0, null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_installations_on_user_id"
  end

  create_table "motor_alert_locks", force: :cascade do |t|
    t.bigint "alert_id", null: false
    t.string "lock_timestamp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alert_id", "lock_timestamp"], name: "index_motor_alert_locks_on_alert_id_and_lock_timestamp", unique: true
    t.index ["alert_id"], name: "index_motor_alert_locks_on_alert_id"
  end

  create_table "motor_alerts", force: :cascade do |t|
    t.bigint "query_id", null: false
    t.string "name", null: false
    t.text "description"
    t.text "to_emails", null: false
    t.boolean "is_enabled", default: true, null: false
    t.text "preferences", null: false
    t.bigint "author_id"
    t.string "author_type"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "motor_alerts_name_unique_index", unique: true, where: "(deleted_at IS NULL)"
    t.index ["query_id"], name: "index_motor_alerts_on_query_id"
    t.index ["updated_at"], name: "index_motor_alerts_on_updated_at"
  end

  create_table "motor_api_configs", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.text "preferences", null: false
    t.text "credentials", null: false
    t.text "description"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "motor_api_configs_name_unique_index", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "motor_audits", force: :cascade do |t|
    t.string "auditable_id"
    t.string "auditable_type"
    t.string "associated_id"
    t.string "associated_type"
    t.bigint "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.bigint "version", default: 0
    t.text "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at", precision: nil
    t.index ["associated_type", "associated_id"], name: "motor_auditable_associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "motor_auditable_index"
    t.index ["created_at"], name: "index_motor_audits_on_created_at"
    t.index ["request_uuid"], name: "index_motor_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "motor_auditable_user_index"
  end

  create_table "motor_configs", force: :cascade do |t|
    t.string "key", null: false
    t.text "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_motor_configs_on_key", unique: true
    t.index ["updated_at"], name: "index_motor_configs_on_updated_at"
  end

  create_table "motor_dashboards", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.text "preferences", null: false
    t.bigint "author_id"
    t.string "author_type"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "motor_dashboards_title_unique_index", unique: true, where: "(deleted_at IS NULL)"
    t.index ["updated_at"], name: "index_motor_dashboards_on_updated_at"
  end

  create_table "motor_forms", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.text "api_path", null: false
    t.string "http_method", null: false
    t.text "preferences", null: false
    t.bigint "author_id"
    t.string "author_type"
    t.datetime "deleted_at", precision: nil
    t.string "api_config_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "motor_forms_name_unique_index", unique: true, where: "(deleted_at IS NULL)"
    t.index ["updated_at"], name: "index_motor_forms_on_updated_at"
  end

  create_table "motor_note_tag_tags", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "note_id", null: false
    t.index ["note_id", "tag_id"], name: "motor_note_tags_note_id_tag_id_index", unique: true
    t.index ["tag_id"], name: "index_motor_note_tag_tags_on_tag_id"
  end

  create_table "motor_note_tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "motor_note_tags_name_unique_index", unique: true
  end

  create_table "motor_notes", force: :cascade do |t|
    t.text "body"
    t.bigint "author_id"
    t.string "author_type"
    t.string "record_id", null: false
    t.string "record_type", null: false
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id", "author_type"], name: "motor_notes_author_id_author_type_index"
    t.index ["record_id", "record_type"], name: "motor_notes_record_id_record_type_index"
  end

  create_table "motor_notifications", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.bigint "recipient_id", null: false
    t.string "recipient_type", null: false
    t.string "record_id"
    t.string "record_type"
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_id", "recipient_type"], name: "motor_notifications_recipient_id_recipient_type_index"
    t.index ["record_id", "record_type"], name: "motor_notifications_record_id_record_type_index"
  end

  create_table "motor_queries", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.text "sql_body", null: false
    t.text "preferences", null: false
    t.bigint "author_id"
    t.string "author_type"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "motor_queries_name_unique_index", unique: true, where: "(deleted_at IS NULL)"
    t.index ["updated_at"], name: "index_motor_queries_on_updated_at"
  end

  create_table "motor_reminders", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.string "author_type", null: false
    t.bigint "recipient_id", null: false
    t.string "recipient_type", null: false
    t.string "record_id"
    t.string "record_type"
    t.datetime "scheduled_at", precision: nil, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id", "author_type"], name: "motor_reminders_author_id_author_type_index"
    t.index ["recipient_id", "recipient_type"], name: "motor_reminders_recipient_id_recipient_type_index"
    t.index ["record_id", "record_type"], name: "motor_reminders_record_id_record_type_index"
    t.index ["scheduled_at"], name: "index_motor_reminders_on_scheduled_at"
  end

  create_table "motor_resources", force: :cascade do |t|
    t.string "name", null: false
    t.text "preferences", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_motor_resources_on_name", unique: true
    t.index ["updated_at"], name: "index_motor_resources_on_updated_at"
  end

  create_table "motor_taggable_tags", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "taggable_id", null: false
    t.string "taggable_type", null: false
    t.index ["tag_id"], name: "index_motor_taggable_tags_on_tag_id"
    t.index ["taggable_id", "taggable_type", "tag_id"], name: "motor_polymorphic_association_tag_index", unique: true
  end

  create_table "motor_tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "motor_tags_name_unique_index", unique: true
  end

  create_table "pipelines", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.string "identifier", default: "", null: false
    t.integer "amount_in_cents", default: 0, null: false
    t.integer "quantity_available", default: 0, null: false
    t.text "description", default: "", null: false
    t.string "name", default: "", null: false
    t.jsonb "custom_attributes", default: {}
    t.jsonb "additional_attributes", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stages", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.bigint "pipeline_id", null: false
    t.integer "position", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pipeline_id"], name: "index_stages_on_pipeline_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "tag_id"
    t.string "taggable_type"
    t.bigint "taggable_id"
    t.string "tagger_type"
    t.bigint "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger_type_and_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "full_name", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.string "language", default: "", null: false
    t.jsonb "notifications", default: "{\"webpush_notify_on_event_expired\":false}", null: false
    t.string "avatar_url", default: "", null: false
    t.string "job_description", default: "other", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "webhooks", force: :cascade do |t|
    t.string "url", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "active"
  end

  create_table "webpush_subscriptions", force: :cascade do |t|
    t.string "endpoint", default: "", null: false
    t.string "auth_key", default: "", null: false
    t.string "p256dh_key", default: "", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_webpush_subscriptions_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "deal_assignees", "deals"
  add_foreign_key "deal_assignees", "users"
  add_foreign_key "deal_products", "deals"
  add_foreign_key "deal_products", "products"
  add_foreign_key "deals", "contacts"
  add_foreign_key "deals", "stages"
  add_foreign_key "deals", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "motor_alert_locks", "motor_alerts", column: "alert_id"
  add_foreign_key "motor_alerts", "motor_queries", column: "query_id"
  add_foreign_key "motor_note_tag_tags", "motor_note_tags", column: "tag_id"
  add_foreign_key "motor_note_tag_tags", "motor_notes", column: "note_id"
  add_foreign_key "motor_taggable_tags", "motor_tags", column: "tag_id"
  add_foreign_key "stages", "pipelines"
  add_foreign_key "taggings", "tags"
  add_foreign_key "webpush_subscriptions", "users"
end
