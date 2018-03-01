require 'resque/tasks'
require 'resque/pool/tasks'
require 'resque/scheduler/tasks'

namespace :resque do
  task setup: :environment

  namespace :pool do
    task :setup do
      ActiveRecord::Base.connection.disconnect!

      Resque::Pool.config_loader = lambda { |env|
        worker_queues = ENV['QUEUE'] || '*'
        worker_count = (ENV['COUNT'] || 2).to_i
        { worker_queues => worker_count }
      }

      Resque::Pool.after_prefork do |job|
        ActiveRecord::Base.establish_connection
        Resque.redis.client.reconnect
      end
    end
  end

  task :quit_instance_workers do
    worker_pids = `ps axu | grep resque | grep $(whoami) | awk '!/grep/ && !/rake/ {print $2}'`.split(/\n/)
    worker_pids.each do |pid|
      `kill -QUIT #{pid}`
    end
  end
end
