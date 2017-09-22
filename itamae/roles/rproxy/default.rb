include_recipe '../../roles/base/default.rb'
include_recipe '../../cookbooks/nginx/default.rb'

%w(
  default
  wlc
  zabbix
  grafana
).each do |_|
  template "/etc/nginx/conf.d/#{_}.conf" do
    owner 'root'
    group 'root'
    mode  '0644'
    notifies :reload, 'service[nginx]'
  end
end

file "/etc/nginx/htpasswd" do
  content "#{node[:secrets][:htpasswd]}\n"
  owner 'http'
  group 'http'
  mode  '0600'
end

service 'nginx' do
  action [:enable, :start]
end
