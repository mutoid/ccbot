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

ActiveRecord::Schema.define(version: 20160317225850) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "megamojis", force: :cascade do |t|
    t.string   "base_name"
    t.integer  "width"
    t.integer  "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pins", force: :cascade do |t|
    t.text     "text"
    t.string   "channel_id"
    t.string   "channel_name"
    t.string   "slack_timestamp"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "author_id"
    t.integer  "pinner_id"
  end

  add_index "pins", ["author_id"], name: "index_pins_on_author_id", using: :btree
  add_index "pins", ["pinner_id"], name: "index_pins_on_pinner_id", using: :btree

  create_table "run_commands", force: :cascade do |t|
    t.string   "command"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "user_id"
  end

  add_index "run_commands", ["user_id"], name: "index_run_commands_on_user_id", using: :btree

  create_table "user_privileges", force: :cascade do |t|
    t.integer  "power_user"
    t.integer  "admin_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "user_id"
  end

  add_index "user_privileges", ["user_id"], name: "index_user_privileges_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "user_id"
    t.string   "user_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
