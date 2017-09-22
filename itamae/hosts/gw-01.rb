node.reverse_merge!(
  cloud_router: {
    primary_ip: '10.24.128.1/24',
    vpns: {
      venue: {
        leftsubnet: '0.0.0.0/0',
        rightsubnet: '0.0.0.0/0',
        leftid: "@gw-01.cloud.i.#{node.fetch(:site_domain)}",
        rightid: "@rt-01.venue.l.#{node.fetch(:site_domain)}",
        left: '59.106.211.253',
        right: '%any',
        ifname: 'venue',
        inner_left: '169.254.24.1/30',
        inner_right: '169.254.24.2/30',
        static_routes: %w(10.24.0.0/17),
        mark: 20,
        ikelifetime: '21600s',
        keylife: '3600s',
        rekeymargin: '600s',
        keyexchange: 'ikev1',
        aggressive: true,
        mobike: true,
        ike: 'aes128-sha1-modp2048',
        esp: 'aes128-sha1-modp2048',
        psk: node[:secrets][:ipsec_psk],
      },
    },
  },
)
