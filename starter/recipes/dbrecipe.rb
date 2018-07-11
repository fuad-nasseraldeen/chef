include_recipe 'apt::default'
# install mysql, using the MySQL cookbook resource

package "mysql-server"

mysql_service 'default' do
  version '5.7'
  bind_address '0.0.0.0'
  port '3306'
  data_dir '/data'
  initial_root_password 'admin1'
  action [:create, :start]
end

directory "#{node[:regapp][:data_dir]}" do
  owner node[:regapp][:user]
  group node[:regapp][:group]
  mode 00777
  action :create
end

cookbook_file "#{node[:regapp][:data_dir]}loaddb.txt" do
  source 'loaddb.txt'
  owner node[:regapp][:user]
  group node[:regapp][:group]
  mode '0755'
  action :create
end

bash 'setup_mysql' do
  code <<-EOH
        sudo mysql -h 127.0.0.1 -u root -p#{node[:regapp][:password]} -S /var/run/mysql-default/mysqld.sock
        sudo mysql -h 127.0.0.1 -u root -p#{node[:regapp][:password]} < "#{node[:regapp][:data_dir]}loaddb.txt"
		    sudo mysql -h 127.0.0.1 -u root -p#{node[:regapp][:password]} -e "GRANT ALL ON *.*  TO 'root'@'%' IDENTIFIED BY '#{node[:regapp][:password]}';"
  EOH
end