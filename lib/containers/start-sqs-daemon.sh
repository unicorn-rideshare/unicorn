#!/usr/bin/env bash
set -e

bundle exec rake db:migrate
exec bundle exec rake sqs_daemon:start
