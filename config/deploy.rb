default_run_options[:pty] = true

set :application, "jotto-server"
set :repository,  "https://github.com/camertron/jotto-server.git"
set :scm, :git
set :copy_strategy, :export
set :keep_releases, 5
set :branch, "master"
set :deploy_to, "/usr/local/jotto-server"
set :user, ENV["user"] || "ubuntu"
set :default_environment, { 'PATH' => "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH" }

ssh_options[:user] = "ubuntu"
ssh_options[:keys] = ["~/.ssh/jotto.pem"]

role :app, "ec2-107-21-159-239.compute-1.amazonaws.com"
role :db,  "ec2-107-21-159-239.compute-1.amazonaws.com", :primary => true

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end