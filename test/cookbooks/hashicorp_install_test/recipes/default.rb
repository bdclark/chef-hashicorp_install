
hashicorp_binary 'consul' do
  version '0.9.3'
end

hashicorp_service_user 'consul'

hashicorp_service 'consul' do
  user 'consul'
  command '/usr/local/bin/consul agent -dev'
end

service 'consul' do
  action :start
end
