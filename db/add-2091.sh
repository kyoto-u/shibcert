#!/bin/sh

rails generate migration AddPassToCerts pass_id:string pass_pin:string pass_p12:string

# bundle exec rake db:migrate
# bundle exec rake db:migrate RAILS_ENV=production

