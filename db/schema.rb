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

ActiveRecord::Schema[7.0].define(version: 2024_03_13_153842) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "characters", force: :cascade do |t|
    t.bigint "story_id", null: false
    t.string "name"
    t.string "gender"
    t.text "personality"
    t.string "job"
    t.text "introduce"
    t.string "stuff"
    t.text "evidence", array: true
    t.boolean "is_criminal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_characters_on_story_id"
  end

  create_table "players", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "character_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_players_on_character_id"
    t.index ["room_id"], name: "index_players_on_room_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.bigint "story_id"
    t.boolean "solved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "victim"
    t.index ["story_id"], name: "index_rooms_on_story_id"
  end

  create_table "stories", force: :cascade do |t|
    t.string "name"
    t.string "set"
    t.text "body"
    t.string "weapon"
    t.string "place"
    t.string "time"
    t.string "victim"
    t.string "v_gender"
    t.string "v_personality"
    t.string "v_job"
    t.text "confession"
    t.text "all"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "characters", "stories"
  add_foreign_key "players", "characters"
  add_foreign_key "players", "rooms"
  add_foreign_key "rooms", "stories"
end
