#
# Cookbook Name:: hashicorp_install
#
# Copyright 2017 Brian Clark
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

resource_name :hashicorp_service_systemd

provides :hashicorp_service, os: 'linux' do |_node|
  Chef::Platform::ServiceHelpers.service_resource_providers.include?(:systemd)
end

property :service_name, name_property: true
property :command, String, required: true
property :user, String, required: true
property :stop_signal, String, default: 'SIGTERM'
property :reload_signal, String, default: 'SIGHUP'
property :environment, Hash, default: {}

default_action :create

action :create do
  execute "#{new_resource.service_name} daemon-reload" do
    command 'systemctl daemon-reload'
    action :nothing
  end

  template service_path do
    source 'systemd.service.erb'
    cookbook 'hashicorp_install'
    owner 'root'
    group node['root_group']
    mode '0755'
    variables(
      name: new_resource.service_name,
      command: new_resource.command,
      environment: new_resource.environment,
      stop_signal: new_resource.stop_signal,
      reload_signal: new_resource.reload_signal,
      user: new_resource.user
    )
    notifies :run, "execute[#{new_resource.service_name} daemon-reload]", :immediately
  end
end

action :remove do
  service new_resource.service_name do
    action [:stop, :disable]
    only_if { ::File.exist?(service_path) }
  end

  execute "#{new_resource.service_name} daemon-reload" do
    command 'systemctl daemon-reload'
    action :nothing
  end

  file service_path do
    action :delete
    notifies :run, "execute[#{new_resource.service_name} daemon-reload]", :immediately
  end
end

action_class do
  def whyrun_supported?
    true
  end

  def service_path
    "/etc/systemd/system/#{new_resource.service_name}.service"
  end
end
