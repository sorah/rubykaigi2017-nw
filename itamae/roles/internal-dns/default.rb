hosts = <<EOF.lines.map { |l| ip, name, iface = l.chomp.split(?\t, 3); {ip: ip, name: name, dc: ip.match('10.24.128.') ? 'cloud' : 'venue', iface: (iface && !iface.empty?) ? iface : nil} }
10.24.0.1	rt-01	
10.24.0.2	sw-01	
10.24.0.3	sv-01	
10.24.0.40	sw-phx-01	
10.24.0.12	sw-phx-02	
10.24.0.13	esw-phx-01	
10.24.0.11	sw-him-01	
10.24.0.31	esw-bck-01	
10.24.0.41	esw-him-01	
10.24.0.51	esw-cos-01	
10.24.0.61	esw-ran-01	
10.24.0.70	sw-csb-01	
10.24.0.80	sw-dah-01	
10.24.0.81	esw-dah-01	
10.24.0.82	esw-dah-02	
10.24.10.53	dns-cache-01	
10.24.10.80	debug-edge-01	
10.24.10.254	rt-01	vl-srv
10.24.11.31	ap-dah-01	
10.24.11.32	ap-dah-02	
10.24.11.33	ap-dah-03	
10.24.11.34	ap-dah-04	
10.24.11.35	ap-dah-11	
10.24.11.36	ap-dah-12	
10.24.11.37	ap-dah-13	
10.24.11.38	ap-dah-14	
10.24.11.41	ap-him-01	
10.24.11.42	ap-him-02	
10.24.11.43	ap-him-11	
10.24.11.44	ap-him-12	
10.24.11.51	ap-cos-01	
10.24.11.52	ap-cos-02	
10.24.11.53	ap-cos-11	
10.24.11.54	ap-cos-21	
10.24.11.55	ap-cos-22	
10.24.11.61	ap-ran-01	
10.24.11.62	ap-ran-02	
10.24.11.81	ap-bck-01	
10.24.11.91	ap-fb2-01	
10.24.11.92	ap-fb2-11	
10.24.11.93	ap-fb2-12	
10.24.11.94	ap-fb2-21	
10.24.11.95	ap-fb2-22	
10.24.11.101	ap-phx-01	
10.24.11.102	ap-phx-02	
10.24.11.103	ap-phx-03	
10.24.11.104	ap-phx-04	
10.24.11.105	ap-phx-05	
10.24.11.111	ap-phx-11	
10.24.11.112	ap-phx-12	
10.24.11.113	ap-phx-13	
10.24.11.121	ap-phx-21	
10.24.11.122	ap-phx-22	
10.24.11.123	ap-phx-23	
10.24.11.124	ap-phx-24	
10.24.11.125	ap-phx-25	
10.24.11.254	rt-01	vl-ap
10.24.100.254	rt-01	vl-adm
10.24.110.254	rt-01	vl-cast
10.24.127.255	rt-01	vl-user
10.24.128.1	gw-01	
10.24.128.2	dns-01	
10.24.128.3	dhcp-01	
10.24.128.4	zabbix-01	
10.24.128.5	syslog-01	
10.24.128.6	wlc-01	
EOF

###

include_recipe '../../cookbooks/nsd/default.rb'

node.reverse_merge!(
  internal_dns: {
    zones: {
      :l => "l.#{node.fetch(:site_domain)}",
      :x => "x.#{node.fetch(:site_domain)}",
      :"in-addr.arpa" => node.fetch(:site_rdomain),
    },
  },
)

zones = node[:internal_dns].fetch(:zones)
node.reverse_merge!(
  dns_cache: {
    stubs: zones.each_value.map { |name| {zone: "#{name}.", addr: '127.0.0.1@10053'} },
  },
)

template "/etc/nsd/nsd.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
end

directory '/var/db/nsd' do
  owner 'nsd'
  group 'root'
  mode  '0755'
end

serial = Time.now.to_i
zones.each do |file, zone|
  template "/var/db/nsd/#{file}.zone" do
    owner 'root'
    group 'root'
    mode  '0755'
    variables zone: "#{zone}.", hosts: hosts, serial: serial
    notifies :run, 'execute[nsd-control reload]'
  end
end

service 'nsd' do
  action [:enable, :start]
end

execute 'nsd-control reload' do
  action :nothing
end
