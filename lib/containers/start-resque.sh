#!/usr/bin/env bash
set -e

source /etc/profile.d/rvm.sh

git pull origin master

bundle install
bundle exec rake assets:precompile
bundle exec rake db:migrate

exec bundle exec resque-pool --environment production
