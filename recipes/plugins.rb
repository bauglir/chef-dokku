node['dokku']['plugins'].each do |plugin_name, repo_url|
  git "#{node['dokku']['plugin_path']}/#{plugin_name}" do
    repository repo_url
    action :sync
  end
end

# The nginx install script does some stuff we don't want
# nuke it and do the install manually
# Can be removed once https://github.com/progrium/dokku/pull/276 is merged
file "#{node['dokku']['plugin_path']}/nginx-vhosts/install" do
  action :delete
end

template "/etc/init/nginx-reloader.conf" do
  source "plugins/nginx-vhosts/nginx-reloader.conf"
  action :create_if_missing
  owner 'root'
  group 'root'
end

template "/etc/nginx/conf.d/dokku.conf" do
  source "plugins/nginx-vhosts/dokku.conf"
  action :create_if_missing
  owner 'root'
  group 'root'
end

service "nginx-reloader" do
  provider Chef::Provider::Service::Upstart
  action :start
end

bash "dokku_plugins_install" do
  cwd node['dokku']['plugin_path']
  code <<-EOH
    dokku plugins-install
  EOH
  only_if { node['dokku']['sync']['plugins'] }
end
