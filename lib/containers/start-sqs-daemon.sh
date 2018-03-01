#!/usr/bin/env bash
set -e

source /etc/profile.d/rvm.sh

git pull origin master

bundle install
bundle exec rake db:migrate

exec bundle exec rake sqs_daemon:start
