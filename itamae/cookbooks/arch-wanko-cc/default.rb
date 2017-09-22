execute 'import C48DBD97.pem' do
  command 'pacman-key -a /etc/C48DBD97.pem && pacman-key --lsign-key C48DBD97'
  action :nothing
  notifies :run, 'execute[pacman -Sy]'
end

remote_file '/etc/C48DBD97.pem' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[import C48DBD97.pem]'
end

file '/etc/pacman.conf' do
  action :edit
  server = "[aur-eagletmt]\nSigLevel = Required\nServer = http://arch.wanko.cc/$repo/os/$arch"

  block do |content|
    if content =~ /^\[aur-eagletmt\]/
      content.gsub!(/^\[aur-eagletmt\].*\n.*\n.*$/, server)
    else
      content << server << "\n"
    end
  end
end
