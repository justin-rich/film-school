namespace :app do
    
  desc "Run app in foreground"
  task :run do
    sh "bundle exec unicorn -l 0.0.0.0:3000"
  end

  desc "Start app server"
  task :start do
    sh "bundle exec unicorn -D -c config/unicorn.rb"
  end

  desc "Stop app server"
  task :stop do
    begin
      Process.kill("QUIT", File.read("tmp/unicorn.pid").to_i)
      puts "Unicorn stopped"
    rescue
      puts "PID not found"
    end
  end

  desc 'Restart app server'
  task :restart => [:stop, :start]

  desc "Start app IRB session"
  task :shell do
    sh "bundle exec racksh"
  end
  
end