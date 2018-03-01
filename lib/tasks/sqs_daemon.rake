# NOTE: to start as daemon, use this:
#   BACKGROUND=y PIDFILE=daemon.pid LOG_LEVEL=info bundle exec rake sqs_daemon:start
#  to stop:  kill `cat daemon.pid`

namespace :sqs_daemon do
  task :start => :environment do
    Rails.logger = Logger.new(Rails.root.join('log', 'sqs_daemon.log'))
    Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)

    if ENV['BACKGROUND']
      Process.daemon(true, true)
    end

    if ENV['PIDFILE']
      File.open(ENV['PIDFILE'], 'w') { |f| f << Process.pid }
    end

    Signal.trap('TERM') { abort }
    Signal.trap('QUIT') { abort }

    sqs_queue = ENV['AWS_SQS_QUEUE']
    sqs_region = ENV['AWS_REGION'] || 'us-east-1'
    raise 'No SQS queue configured via AWS_SQS_QUEUE environment variable; AWS daemon not starting.' unless sqs_queue
    max_messages = (ENV['AWS_DEFAULT_SQS_QUEUE_MAX_NUMBER_OF_MESSAGES'] || 10).to_i
    wait_time_seconds = (ENV['AWS_DEFAULT_SQS_QUEUE_WAIT_TIME_SECONDS'] || 10).to_i

    Rails.logger.info("Starting AWS daemon listening to SQS queue #{sqs_queue}; wait time: #{wait_time_seconds} seconds.")
    sqs = Aws::SQS::Client.new(region: sqs_region)
    sqs_poller = Aws::SQS::QueuePoller.new(sqs_queue, client: sqs)

    poll = true
    while poll
      sqs_poller.poll(max_number_of_messages: max_messages, wait_time_seconds: wait_time_seconds) do |messages|
        messages.each do |msg|
          begin
            result = AwsMessageService.dispatch(msg.body)
            Rails.logger.warn(result) unless result.blank?
          rescue Exception => e
            Rails.logger.warn(e)
          end
        end
      end
    end

    Rails.logger.info("AWS daemon stopped polling SQS queue #{sqs_queue}")
  end
end
