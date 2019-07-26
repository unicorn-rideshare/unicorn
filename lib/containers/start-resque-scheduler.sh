#!/usr/bin/env bash
set -e

source /etc/profile.d/rvm.sh
exec bundle exec rake environment resque:scheduler
