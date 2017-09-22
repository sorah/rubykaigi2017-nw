node.reverse_merge!(
  dns_cache: {
    threads: 2,
    upstream: nil,
    interfaces: %w(0.0.0.0 ::0),
    outgoing_interfaces: %w(),
    log_queries: false,
    stubs: [],
  },
)

1.upto(100) do |i|
  node[:dns_cache][:slab] = 2**i
  if node[:dns_cache][:slab] >= node[:dns_cache][:threads]
    break
  end
end

include_recipe '../../cookbooks/unbound/default.rb'
include_recipe '../../cookbooks/zabbix-userparameter-unbound/default.rb'

template "/etc/unbound/unbound.conf" do
  owner "root"
  group "root"
  mode  "0644"
end

directory "/var/log/unbound" do
  owner "unbound"
  group "unbound"
  mode  "0755"
end

remote_file "/etc/unbound/named.cache" do
  owner 'root'
  group 'root'
  mode  '0644'
end

service "unbound" do
  action [:enable, :start]
end
