#!/usr/bin/env bash
set -e

source /etc/profile.d/rvm.sh

git pull origin master

bundle install

exec bundle exec rake environment resque:scheduler
