node.reverse_merge!(
  kea: {
    interfaces: %w(*),
    relay_only: true,
  },
)

include_recipe '../../roles/base/default.rb'
include_recipe '../../cookbooks/kea/default.rb'
include_recipe '../../cookbooks/zabbix-userparameter-kea/default.rb'

conf = {
  Dhcp4: {
    "control-socket" => {
      "socket-type" => "unix",
      "socket-name" => "/run/kea/kea.sock",
    },
    "interfaces-config" => {
      interfaces: node[:kea][:interfaces],
      "dhcp-socket-type" => node[:kea][:relay_only] ? 'udp' : 'raw',
    },
    "lease-database" => {
      type: "memfile",
      persist: true,
      name: "/var/db/kea/dhcp4.leases",
    },
    "expired-leases-processing" => {
      "reclaim-timer-wait-time" => 10,
      "flush-reclaimed-timer-wait-time" => 25,
      "hold-reclaimed-time" => 1800,
      "max-reclaim-leases" => 500,
      "max-reclaim-time" => 250,
      "unwarned-reclaim-cycles" => 2,
    },
    "valid-lifetime" => 10800,
    "renew-timer" => 5400,
    "rebind-timer" => 7200,
    subnet4: [
      {
        subnet: "10.24.11.0/24",
        id: 11,
        pools: [
          pool: "10.24.11.200-10.24.11.250",
        ],
        "option-data" => [
          {
            name: "routers",
            code: 3,
            space: "dhcp4",
            "csv-format" => true,
            data: "10.24.11.254",
          },
          {
            name: "domain-name",
            code: 15,
            space: "dhcp4",
            "csv-format" => true,
            data: "venue.l.#{node.fetch(:site_domain)}",
          }
        ],
        reservations: [
          %w(
10.24.11.1	ap-01		de:ad:be:ef:00:00
10.24.11.2	ap-02		8b:ad:f0:0d:00:00
          ).each_slice(3).map { |ip,name,mac|
            {
              "hw-address" => mac.downcase,
              "ip-address" => ip,
              "hostname"   => name,
            }
          }
        ].flatten,
      },
      {
        subnet: "10.24.100.0/24",
        id: 100,
        pools: [
          {
            pool: "10.24.100.50-10.24.100.250",
          },
        ],
        "option-data" => [
          {
            name: "routers",
            code: 3,
            space: "dhcp4",
            "csv-format" => true,
            data: "10.24.100.254",
          },
        ],
      },
      {
        subnet: "10.24.112.0/20",
        id: 112,
        pools: [
          {
            pool: "10.24.113.0-10.24.127.250",
          },
        ],
        "option-data" => [
          {
            name: "routers",
            code: 3,
            space: "dhcp4",
            "csv-format" => true,
            data: "10.24.127.254",
          },
        ],
      },
      {
        subnet: "10.24.110.0/24",
        id: 110,
        pools: [
          {
            pool: "10.24.110.50-10.24.110.250",
          },
        ],
        "option-data" => [
          {
            name: "routers",
            code: 3,
            space: "dhcp4",
            "csv-format" => true,
            data: "10.24.110.254",
          },
        ],
      },
    ],
    "option-data" => [
      {
        name: "domain-name-servers",
        code: 6,
        space: "dhcp4",
        "csv-format" => true,
        data: "10.24.10.53,10.24.128.2", # comma separated
      },
    ],
  },

  Logging: {
    loggers: [
      {
        name: "kea-dhcp4",
        output_options: [
          {
            output: "/var/log/kea/kea.log",
            maxsize: 1000000,
          },
        ],
        severity: "INFO",
      },
    ],
  },
}

file "/etc/kea/kea.conf" do
  content "#{conf.to_json}\n"
  owner 'root'
  group 'root'
  mode  '0644'
end

service "kea-dhcp4" do
  action [:enable, :start]
end

