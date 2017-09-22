include_recipe '../../cookbooks/nginx/default.rb'

template "/etc/nginx/conf.d/edge.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :reload, 'service[nginx]'
end

directory "/var/www/debug-edge" do
  owner 'root'
  group 'root'
  mode  '0755'
end

execute "curl -LSsf -o /var/www/debug-edge/data.svg https://raw.githubusercontent.com/sorah/wifidiag/master/app/public/data.svg" do
  not_if "test -e /var/www/debug-edge/data.svg"
end

execute "curl -LSsf -o /var/www/debug-edge/tiny.svg https://raw.githubusercontent.com/sorah/wifidiag/master/app/public/tiny.svg" do
  not_if "test -e /var/www/debug-edge/tiny.svg"
end

service 'nginx' do
  action [:enable, :start]
end
