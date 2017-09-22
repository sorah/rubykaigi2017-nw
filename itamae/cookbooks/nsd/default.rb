package 'nsd'

execute "nsd-control-setup" do
  user "root"
  not_if "test -e /etc/nsd/nsd_control.key"
end
