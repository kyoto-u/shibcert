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

ActiveRecord::Schema.define(version: 2019_03_14_113913) do

  create_table "certs", force: :cascade do |t|
    t.datetime "get_at"
    t.datetime "expire_at"
    t.string "pin"
    t.datetime "pin_get_at"
    t.integer "user_id"
    t.integer "cert_state_id"
    t.integer "cert_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "state"
    t.integer "purpose_type"
    t.string "serialnumber"
    t.string "dn"
    t.string "memo"
    t.integer "req_seq"
    t.integer "revoke_reason"
    t.string "revoke_comment"
    t.string "vlan_id"
    t.integer "download_type", default: 1
    t.datetime "url_expire_at"
    t.string "pass_id"
    t.string "pass_pin"
    t.string "pass_p12"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.string "email"
    t.integer "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "provider"
    t.integer "cert_serial_max", default: 0
    t.boolean "admin", default: false, null: false
    t.string "number"
  end

end
