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

resource_name :hashicorp_service_sysvinit

provides :hashicorp_service, os: 'linux'

property :service_name, name_property: true
property :command, String, required: true
property :user, String, required: true
property :stop_signal, String, default: 'SIGTERM'
property :reload_signal, String, default: 'SIGHUP'
property :environment, Hash, default: {}
property :log_directory, String

default_action :create

action :create do
  directory log_directory do
    owner new_resource.user
    group node['root_group']
    mode '0755'
    recursive true
    action :create
  end

  parts = new_resource.command.split(/ /, 2)
  daemon = ENV['PATH'].split(/:/)
                      .map { |path| ::File.absolute_path(parts[0], path) }
                      .find { |path| ::File.exist?(path) } || parts[0]

  template "/etc/init.d/#{new_resource.service_name}" do
    source 'sysvinit.service.erb'
    cookbook 'hashicorp_install'
    owner 'root'
    group node['root_group']
    mode '0755'
    variables(
      name: new_resource.service_name,
      daemon: daemon,
      daemon_options: parts[1].to_s,
      environment: new_resource.environment,
      stop_signal: new_resource.stop_signal,
      reload_signal: new_resource.reload_signal,
      user: new_resource.user,
      log_dir: log_directory
    )
  end
end

action :remove do
  service new_resource.service_name do
    action [:stop, :disable]
    only_if { ::File.exist?(service_path) }
  end

  file service_path do
    action :delete
  end
end

action_class do
  def whyrun_supported?
    true
  end

  def log_directory
    new_resource.log_directory || "/var/log/#{new_resource.service_name}"
  end

  def service_path
    "/etc/init.d/#{new_resource.service_name}"
  end
end
