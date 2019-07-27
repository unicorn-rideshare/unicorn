#!/usr/bin/env bash
set -e

source /etc/profile.d/rvm.sh

sudo service nginx start
bundle exec rake db:migrate
bundle exec rake websocket_rails:start_server
exec bundle exec unicorn -E production -c config/unicorn.rb
