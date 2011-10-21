#
# Cookbook Name:: redmine
# Attributes:: redmine
#
# Copyright 2011, Christian Trabold
# Copyright 2009, Opscode, Inc
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

require 'openssl'

pw = String.new

while pw.length < 20
  pw << OpenSSL::Random.random_bytes(1).gsub(/\W/, '')
end

#database_server = search(:node, "database_master:true").map {|n| n['fqdn']}.first

set[:redmine][:dir] = "/srv/redmine-#{redmine[:version]}"

default[:redmine][:dl_id]   = "74944"
default[:redmine][:version] = "1.2.0"

default[:redmine][:db][:type]     = "sqlite"
default[:redmine][:db][:user]     = "redmine"
default[:redmine][:db][:password] = pw
default[:redmine][:db][:database] = "redmine"
default[:redmine][:db][:hostname] = "localhost"

# Ticket #10953: Migrate attributes from rails cookbook for reuse / upwards compatibility
# TODO ct 2011-05-25 Check / resolve sideeffects in cookbook 'passenger_apache2'
default[:rails][:version]       = false
default[:rails][:environment]   = "production"
default[:rails][:max_pool_size] = 4
## End Migrate attributes

default[:redmine][:rails][:version]       = false
default[:redmine][:rails][:environment]   = "production"
default[:redmine][:rails][:max_pool_size] = 4
