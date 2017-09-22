node.reverse_merge!(
  syslog: {
    root: '/mnt/vol/log',
  },
)

include_recipe '../../cookbooks/fluentd/default.rb'
include_recipe '../../cookbooks/nftables/default.rb'

directory '/mnt/vol' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory node[:syslog].fetch(:root) do
  owner 'fluentd'
  group 'root'
  mode  '0755'
end

directory "#{node[:syslog].fetch(:root)}/buffer" do
  owner 'fluentd'
  group 'root'
  mode  '0755'
end

gem_package "fluent-plugin-rewrite-tag-filter"

template '/etc/fluent/fluent.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
end

service 'fluentd' do
  action [:enable, :start]
end


