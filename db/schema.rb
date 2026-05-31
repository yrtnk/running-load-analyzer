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

ActiveRecord::Schema[7.2].define(version: 2026_05_31_065742) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "strava_activity_id", null: false
    t.string "name", null: false
    t.float "distance"
    t.integer "moving_time"
    t.integer "elapsed_time"
    t.float "average_heartrate"
    t.integer "max_heartrate"
    t.float "average_pace"
    t.datetime "start_date"
    t.string "activity_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "strava_activity_id"], name: "index_activities_on_user_id_and_strava_activity_id", unique: true
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "target_times", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "target_marathon_time", null: false
    t.float "target_vdot", null: false
    t.date "revised_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "revised_at"], name: "index_target_times_on_user_id_and_revised_at", unique: true
    t.index ["user_id"], name: "index_target_times_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "strava_uid"
    t.string "strava_access_token"
    t.string "strava_refresh_token"
    t.datetime "strava_token_expires_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["strava_uid"], name: "index_users_on_strava_uid", unique: true
  end

  add_foreign_key "activities", "users"
  add_foreign_key "target_times", "users"
end
