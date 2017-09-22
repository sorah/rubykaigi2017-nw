node.reverse_merge!(
  zabbix_agent: {
    server: "zabbix-01.cloud.l.#{node.fetch(:site_domain)}",
  },
)

package 'zabbix-agent'

template '/etc/zabbix/zabbix_agentd.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, 'service[zabbix-agent]'
end

directory '/etc/zabbix/zabbix_agentd.conf.d' do
  owner 'root'
  group 'root'
  mode  '0755'
end

%w(
  linux
).each do |_|
  remote_file "/etc/zabbix/zabbix_agentd.conf.d/#{_}.conf" do
    owner 'root'
    group 'root'
    mode  '0644'
    notifies :restart, 'service[zabbix-agent]'
  end
end

service 'zabbix-agent' do
  action [:enable, :start]
end
