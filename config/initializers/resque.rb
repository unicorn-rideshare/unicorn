require_relative '../settings'

uri = URI.parse(Settings.redis.url)
redis = Redis.new(host: uri.host, port: uri.port, password: uri.password, timeout: 5)

Resque.redis = redis
Resque.redis.namespace = Settings.redis.namespace

log_file = ENV['RESQUE_WORKER_LOGFILE'] || 'log/resque-worker.log'
Resque.logger = Logger.new(log_file)
Resque.logger.level = ENV['RESQUE_LOG_LEVEL'] ? "Logger::#{ENV['RESQUE_LOG_LEVEL'].to_s.upcase}".constantize : Logger::INFO

require 'resque-scheduler'
require 'resque/scheduler/server'
Resque::Scheduler.dynamic = true

Resque.inline = Rails.env.test?
