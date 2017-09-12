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

resource_name :hashicorp_binary

property :app, String, name_property: true
property :version, String, required: true
property :dir, String, default: lazy { node['hashicorp_install']['bin_dir'] }
property :baseurl, String, default: 'https://releases.hashicorp.com'
property :public_key_content, String, default: lazy { node['hashicorp_install']['key'] }

default_action :install

action :install do
  package 'unzip'
  package 'gnupg'

  bin_dir = directory ::File.join(new_resource.dir, "#{new_resource.app}-#{new_resource.version}") do
    owner 'root'
    group node['root_group']
    mode '0755'
    recursive true
  end

  gpg_home = ::File.join(Chef::Config[:file_cache_path], 'hashicorp.gnupg')

  directory gpg_home do
    owner 'root'
    group node['root_group']
    mode '0700'
    recursive true
  end

  keyfile = file ::File.join(Chef::Config[:file_cache_path], 'hashicorp.asc') do
    content new_resource.public_key_content
    notifies :run, 'execute[import-hashicorp-key]', :immediately
  end

  execute 'import-hashicorp-key' do
    command %(gpg --homedir #{gpg_home} --import #{keyfile.path})
    action :nothing
  end

  checksum_filename = "#{new_resource.app}_#{new_resource.version}_SHA256SUMS"

  checksum_file = remote_file ::File.join(Chef::Config[:file_cache_path], checksum_filename) do
    source ::URI.join(new_resource.baseurl, "#{new_resource.app}/#{new_resource.version}/#{checksum_filename}").to_s
  end

  remote_file ::File.join(Chef::Config[:file_cache_path], "#{checksum_filename}.sig") do
    source ::URI.join(new_resource.baseurl, "#{new_resource.app}/#{new_resource.version}/#{checksum_filename}.sig").to_s
  end

  execute "#{new_resource.app}_#{new_resource.version}-verify-checksum-signature" do
    command %(gpg --homedir #{gpg_home} --batch --verify #{checksum_filename}.sig #{checksum_filename})
    cwd Chef::Config[:file_cache_path]
    action :nothing
  end

  zip = remote_file ::File.join(Chef::Config[:file_cache_path], zip_filename) do
    source ::URI.join(new_resource.baseurl, "#{new_resource.app}/#{new_resource.version}/#{zip_filename}").to_s
    checksum lazy { ::File.readlines(checksum_file.path).select { |line| line =~ /#{zip_filename}$/ }.first.split(' ').first }
    notifies :run, "execute[#{new_resource.app}_#{new_resource.version}-verify-checksum-signature]", :before
  end

  execute "unzip-#{new_resource.app}-#{new_resource.version}" do
    command %(unzip #{zip.path} -d #{bin_dir.path})
    action :run
    creates ::File.join(bin_dir.path, new_resource.app)
  end

  link ::File.join(new_resource.dir, new_resource.app) do
    to ::File.join(bin_dir.path, new_resource.app)
  end
end

action :remove do
  directory ::File.join(new_resource.path, "nomad-#{version}") do
    recursive true
    action :delete
  end
end

action_class do
  def whyrun_supported?
    true
  end

  def zip_filename
    arch =
      case node['kernel']['machine']
      when 'x86_64', 'amd64' then 'amd64'
      when /i\d86/ then '386'
      else node['kernel']['machine']
      end
    "#{new_resource.app}_#{new_resource.version}_#{node['os']}_#{arch}.zip"
  end
end
