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

  create_table "megamojis", force: :cascade do |t|
    t.string   "base_name"
    t.integer  "width"
    t.integer  "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pins", force: :cascade do |t|
    t.string   "author_id"
    t.string   "author_name"
    t.string   "pinner_id"
    t.string   "pinner_name"
    t.text     "text"
    t.string   "channel_id"
    t.string   "channel_name"
    t.string   "slack_timestamp"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "run_commands", force: :cascade do |t|
    t.string   "user_name"
    t.string   "user_id"
    t.string   "command"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_privileges", force: :cascade do |t|
    t.string   "user_id"
    t.integer  "power_user"
    t.integer  "admin_user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
