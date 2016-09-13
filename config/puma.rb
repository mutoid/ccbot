root = "#{Dir.getwd}"
port_num = ENV['WEBHOOK_PORT']     || 3000
threads_count = Integer(ENV['MAX_THREADS'] || 4)

workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads threads_count, threads_count
# pidfile "#{root}/tmp/pids/ccbot.pid"
# state_path "#{root}/tmp/pids/ccbot.state"
rackup      DefaultRackup
port        port_num
environment ENV['RACK_ENV'] || 'development'

bind "tcp://127.0.0.1:#{port_num}"

preload_app!

activate_control_app 
