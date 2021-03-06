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

ActiveRecord::Schema.define(version: 20150127140022) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "audio_blocks", force: true do |t|
    t.string   "type"
    t.string   "key"
    t.integer  "duration"
    t.datetime "estimated_airtime"
    t.integer  "commentary_preceding_overlap"
    t.integer  "song_preceding_overlap"
    t.integer  "commercial_preceding_overlap"
    t.integer  "commentary_following_overlap"
    t.integer  "commercial_following_overlap"
    t.integer  "song_following_overlap"
    t.string   "artist"
    t.string   "title"
    t.string   "album"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "echonest_id"
    t.integer  "station_id"
    t.integer  "current_position"
    t.datetime "airtime"
    t.string   "album_artwork_url"
    t.string   "itunes_track_view_url"
  end

  create_table "commercial_links", force: true do |t|
    t.integer "commercial_id"
    t.integer "audio_block_id"
  end

  create_table "commercials", force: true do |t|
    t.integer  "sponsor_id"
    t.integer  "duration"
    t.string   "key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "genres", force: true do |t|
    t.integer "song_id"
    t.string  "genre"
  end

  create_table "listening_sessions", force: true do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "station_id"
    t.integer  "user_id"
  end

  create_table "log_entries", force: true do |t|
    t.string   "type"
    t.integer  "station_id"
    t.integer  "current_position"
    t.integer  "audio_block_id"
    t.datetime "airtime"
    t.integer  "listeners_at_start"
    t.integer  "listeners_at_finish"
    t.integer  "duration"
    t.boolean  "is_commercial_block"
  end

  create_table "presets", force: true do |t|
    t.integer "user_id"
    t.integer "station_id"
  end

  create_table "sessions", force: true do |t|
    t.string  "session_id"
    t.integer "user_id"
  end

  create_table "spin_frequencies", force: true do |t|
    t.integer "song_id"
    t.integer "station_id"
    t.integer "spins_per_week"
  end

  create_table "spins", force: true do |t|
    t.integer  "current_position"
    t.datetime "airtime"
    t.integer  "audio_block_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "station_id"
  end

  create_table "stations", force: true do |t|
    t.integer  "user_id"
    t.integer  "secs_of_commercial_per_hour"
    t.integer  "spins_per_week"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "last_commercial_block_aired"
    t.integer  "last_accurate_current_position"
    t.integer  "next_commercial_block_id"
    t.datetime "current_playlist_end_time"
    t.datetime "original_playlist_end_time"
    t.float    "average_daily_listeners"
    t.date     "average_daily_listeners_calculation_date"
  end

  create_table "twitter_friends", force: true do |t|
    t.integer  "follower_uid"
    t.integer  "followed_station_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "twitter"
    t.string   "twitter_uid"
    t.string   "email"
    t.integer  "birth_year"
    t.string   "gender"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "zipcode"
    t.string   "timezone"
    t.string   "profile_image_url"
    t.integer  "station_id"
  end

end
