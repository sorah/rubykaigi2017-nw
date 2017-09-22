# ens3: sakura, ens4: global, ens5: private
node.reverse_merge!(
  cloud_router: {
    primary_ip: nil,
    primary_ip6: nil,
    mgmt_table: false,
    mgmt_prefixes: {v4: [], v6: []},
    mgmt_routes: {v4: [], v6: []},
    vpns: {
    }
  }
)

include_recipe '../../cookbooks/nftables/default.rb'
include_recipe '../../cookbooks/strongswan/default.rb'

template '/etc/iproute2/rt_tables' do
  owner 'root'
  group 'root'
  mode  '0644'
end

template '/usr/bin/cnw-setup-mgmt-route' do
  owner 'root'
  group 'root'
  mode  '0755'
end
remote_file '/etc/systemd/system/cnw-mgmt-route.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

if node[:mgmt_route]
  service 'cnw-mgmt-route' do
    action :enable
  end
else
  service 'cnw-mgmt-route' do
    action :disable
  end
end

template '/etc/strongswan.d/charon.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
end

template '/etc/strongswan.d/charon/connmark.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
end

directory '/usr/share/cnw/cloud-router' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/usr/share/cnw/cloud-router/ipsec-updown.sh' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/usr/share/cnw/cloud-router/ipsec-updown-privileged.sh' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/etc/sudoers.d/ipsec-updown' do
  owner 'root'
  group 'root'
  mode  '0600'
end

execute 'strongswan reload' do
  command 'ipsec reload && ipsec rereadsecrets'
  action :nothing
end

template '/etc/ipsec.secrets' do
  owner 'root'
  group 'root'
  mode  '0640'
  notifies :run, 'execute[strongswan reload]'
end

template '/etc/ipsec.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[strongswan reload]'
end

service 'strongswan' do
  action [:enable, :start]
end
