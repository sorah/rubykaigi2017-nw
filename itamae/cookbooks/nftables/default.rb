node.reverse_merge!(
  nftables: {
    config_file: node[:hostname],
  },
)

package 'nftables'

if node[:nftables][:config_file]
  rule_source = node[:nftables][:config_file].kind_of?(String) ? node[:nftables][:config_file] : node[:hostname]

  template "/etc/nftables.conf" do
    source "templates/etc/nftables.#{rule_source}.conf"
    owner 'root'
    group 'wheel'
    mode  '0640'
  end

  service 'nftables' do
    action :enable
  end
end
