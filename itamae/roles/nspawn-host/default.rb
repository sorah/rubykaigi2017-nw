node.reverse_merge!(
  nspawn: {
    machines: {
    },
  },
)

directory '/var/lib/machines' do
  owner 'root'
  group 'root'
  mode  '0755'
end

directory "/etc/systemd/nspawn" do
  owner 'root'
  group 'root'
  mode  '0755'
end

(node.dig(:nspawn, :machines) || {}).each do |name, spec|
  spec.reverse_merge!(
    Exec: {
      Boot: true,
      PrivateUsers: false,
    },
    Network: {
    #  Zone: 'default',
      Bridge: 'br_srv',
    },
    Files: {
      Bind: %w(),
    },
  )
  template "/etc/systemd/nspawn/#{name}.nspawn" do
    source 'templates/etc/systemd/nspawn/template.nspawn'
    owner 'root'
    group 'root'
    mode  '0644'
    variables machine: spec, name: name
  end

  service "systemd-nspawn@#{name}" do
    action :enable
  end
end
