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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130427071750) do

  create_table "article_links", :force => true do |t|
    t.integer  "article_id"
    t.string   "url"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "url_type",    :default => 1
    t.string   "description"
  end

  create_table "articles", :force => true do |t|
    t.string   "title"
    t.string   "author"
    t.text     "body"
    t.integer  "article_type"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "status",       :default => 1
    t.integer  "stage_id"
  end

  create_table "competition_invitations", :force => true do |t|
    t.integer  "competition_id"
    t.integer  "user_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "status",         :default => 1
  end

  create_table "competition_participants", :force => true do |t|
    t.integer  "competition_id"
    t.integer  "user_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "status",         :default => 1
  end

  add_index "competition_participants", ["user_id", "competition_id"], :name => "competition_participants_uid_compid_ndx"

  create_table "competition_stages", :force => true do |t|
    t.integer  "competition_id"
    t.integer  "stage_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "status",         :default => 1
    t.integer  "race_id"
  end

  create_table "competition_tips", :force => true do |t|
    t.integer  "competition_participant_id"
    t.integer  "stage_id"
    t.integer  "rider_id"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "competition_id"
    t.integer  "default_rider_id"
    t.integer  "race_id"
    t.integer  "status",                     :default => 1
    t.boolean  "notification_required",      :default => false
  end

  create_table "competitions", :force => true do |t|
    t.integer  "creator_id"
    t.string   "name"
    t.text     "description"
    t.string   "image_url"
    t.integer  "season_id"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.integer  "status",           :default => 1
    t.string   "invitation_code"
    t.boolean  "is_complete",      :default => false
    t.integer  "competition_type", :default => 1
  end

  create_table "cycling_quotes", :force => true do |t|
    t.text     "quote"
    t.string   "author"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "default_riders", :force => true do |t|
    t.integer  "season_id"
    t.integer  "race_id"
    t.integer  "rider_id"
    t.integer  "order_id"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.integer  "status",     :default => 1
  end

  create_table "metadata", :force => true do |t|
    t.string   "object_type"
    t.integer  "object_id"
    t.string   "title"
    t.string   "data_type"
    t.text     "data"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "race_teams", :force => true do |t|
    t.integer  "team_id"
    t.integer  "race_id"
    t.integer  "status",     :default => 1
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "races", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "image_url"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "status",      :default => 1
    t.integer  "season_id"
    t.boolean  "is_complete", :default => false
  end

  create_table "results", :force => true do |t|
    t.integer  "season_stage_id"
    t.integer  "rider_id"
    t.float    "time"
    t.integer  "kom_points",      :default => 0
    t.integer  "sprint_points",   :default => 0
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.float    "points"
    t.integer  "race_id"
    t.integer  "rider_status",    :default => 1
    t.integer  "status",          :default => 1
    t.integer  "rank",            :default => 0
    t.integer  "bonus_time",      :default => 0
  end

  create_table "riders", :force => true do |t|
    t.string   "name"
    t.string   "photo_url"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.integer  "status",     :default => 1
  end

  create_table "seasons", :force => true do |t|
    t.integer  "year"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.integer  "status",     :default => 2
  end

  create_table "stages", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "image_url"
    t.text     "profile"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.integer  "status",         :default => 1
    t.integer  "race_id"
    t.integer  "order_id"
    t.integer  "season_id"
    t.datetime "starts_on"
    t.string   "start_location"
    t.string   "end_location"
    t.float    "distance_km"
    t.boolean  "is_complete",    :default => false
  end

  create_table "team_riders", :force => true do |t|
    t.integer  "team_id"
    t.integer  "rider_id"
    t.string   "display_name"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "status",       :default => 1
    t.integer  "rider_number", :default => 0
    t.integer  "rider_status", :default => 1
    t.integer  "race_id"
  end

  create_table "teams", :force => true do |t|
    t.string   "name"
    t.integer  "season_id"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.integer  "status",     :default => 1
    t.string   "image_url"
  end

  create_table "users", :force => true do |t|
    t.string   "firstname"
    t.string   "lastname"
    t.string   "email"
    t.string   "password"
    t.string   "salt"
    t.datetime "last_activity"
    t.datetime "created_at",                                              :null => false
    t.datetime "updated_at",                                              :null => false
    t.string   "image_url"
    t.boolean  "is_admin",                          :default => false
    t.integer  "fb_id",                :limit => 8
    t.string   "fb_access_token"
    t.string   "temp_password"
    t.string   "time_zone",                         :default => "+00:00"
    t.string   "display_name"
    t.boolean  "in_grand_competition",              :default => true
  end

end
