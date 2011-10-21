#
# Author: Christian Trabold <cookbooks@christian-trabold.de>
# Author: Joshua Timberman <joshua@housepub.org>
# Cookbook Name:: redmine
# Recipe:: default
#
# Copyright 2011, Christian Trabold
# Copyright 2008-2009, Joshua Timberman
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "apache2"
include_recipe "apache2::mod_rewrite"
include_recipe "passenger_apache2::mod_rails"

gem_package "rails" do
  version node[:redmine][:rails][:version]
end


bash "install_redmine" do
  cwd "/srv"
  user "root"
  code <<-EOH
    wget http://rubyforge.org/frs/download.php/#{node[:redmine][:dl_id]}/redmine-#{node[:redmine][:version]}.tar.gz
    tar xf redmine-#{node[:redmine][:version]}.tar.gz
    chown -R #{node[:apache][:user]} redmine-#{node[:redmine][:version]}
  EOH
  not_if { ::File.exists?("/srv/redmine-#{node[:redmine][:version]}/Rakefile") }
end

link "/srv/redmine" do
  to "/srv/redmine-#{node[:redmine][:version]}"
end

case node[:redmine][:db][:type]
when "sqlite"
  include_recipe "sqlite"
  gem_package "sqlite3-ruby"
  file "/srv/redmine-#{node[:redmine][:version]}/db/production.db" do
    owner node[:apache][:user]
    group node[:apache][:user]
    mode "0644"
  end
when "mysql"
  include_recipe "mysql::client"

  # Create database
  mysql_database "create application_production database '#{node[:redmine][:db][:database]}'" do
    host node[:redmine][:db][:hostname]
    username "root"
    password node[:mysql][:server_root_password]
    database "#{node[:redmine][:db][:database]}"
    action :create_db
  end
end

template "/srv/redmine-#{node[:redmine][:version]}/config/database.yml" do
  source "database.yml.erb"
  owner "root"
  group "root"
  variables :database_server => node[:redmine][:db][:hostname]
  mode "0664"
end

gem_package "i18n" do
  version "0.4.2"
end

template "/srv/redmine-#{node[:redmine][:version]}/config/environment.rb" do
  source "environment.rb.erb"
  owner node[:apache][:user]
  group node[:apache][:user]
  mode "0664"
end

execute "rake db:migrate RAILS_ENV='production'" do
  user node[:apache][:user]
  cwd "/srv/redmine-#{node[:redmine][:version]}"
  not_if { ::File.exists?("/srv/redmine-#{node[:redmine][:version]}/db/schema.rb") }
end

web_app "redmine" do
  docroot "/srv/redmine/public"
  template "redmine.conf.erb"
  server_name "redmine.#{node[:domain]}"
  server_aliases [ "redmine", node[:hostname] ]
  rails_env node[:redmine][:rails][:environment]
  max_pool_size node[:redmine][:rails][:max_pool_size]
end
