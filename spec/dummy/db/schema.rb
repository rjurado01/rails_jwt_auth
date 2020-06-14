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

ActiveRecord::Schema.define do
  create_table 'active_record_users', force: :cascade do |t|
    t.string  'username'
    t.string  'email'

    t.string  'password_digest'
    t.string  'auth_tokens'

    t.string    'unconfirmed_email'
    t.string    'confirmation_token'
    t.datetime  'confirmation_sent_at'
    t.datetime  'confirmed_at'

    t.string    'reset_password_token'
    t.datetime  'reset_password_sent_at'

    t.datetime  'last_sign_in_at'
    t.string    'last_sign_in_ip'
    t.datetime  'last_request_at'
    t.string    'last_request_ip'

    t.string    'invitation_token'
    t.datetime  'invitation_sent_at'
    t.datetime  'invitation_accepted_at'

    t.integer   'failed_attempts'
    t.string    'unlock_token'
    t.datetime  'first_failed_attempt_at'
    t.datetime  'locked_at'
  end
end
