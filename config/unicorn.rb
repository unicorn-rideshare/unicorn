# config/unicorn.rb
# bundle exec unicorn -E production -c config/unicorn.rb

application_root = Dir.pwd
concurrency = Integer(ENV['WEB_CONCURRENCY'] || 8)

working_directory(application_root)
worker_processes(concurrency)

preload_app true
timeout 30

Unicorn::HttpServer::START_CTX[0] = "#{application_root}/bin/unicorn"

`mkdir -p "#{application_root}/tmp"`

listen "#{application_root}/tmp/unicorn.sock", :backlog => Integer(ENV['UNICORN_BACKLOG'] || 2048)
pid "#{application_root}/tmp/unicorn.pid"

stderr_path "#{application_root}/log/unicorn.stderr.log"
stdout_path "#{application_root}/log/unicorn.stdout.log"

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "#{application_root}/Gemfile"
end

before_fork do |server, worker|
  `ps -ef | awk '/unicorn/ && /master/ && !/worker/ {print $2}'`.split(/\n/).map(&:to_i).each do |stale_pid|
    if stale_pid > 0 && File.read(server.pid).to_i != stale_pid
      begin
        Process.kill('QUIT', stale_pid)
      rescue Errno::ENOENT, Errno::ESRCH
        # already quit
      end
    end
  end
end

after_fork do |server, worker|

end
