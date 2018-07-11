#
# Cookbook Name:: regapp
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


remote_directory "#{node[:regapp][:app_dir]}" do
  mode 00777
  owner node[:regapp][:user]
  group node[:regapp][:group]
end


template "#{node[:regapp][:app_dir]}condb.rb" do
	source 'condb.erb'
	variables({
		sqlhost: node[:regapp][:db_ip],
		sqluser: node[:regapp][:db_user],
		sqlpass: node[:regapp][:password],
		dbname: node[:regapp][:db_table]
		})
end



execute "run-app" do
 cwd "#{node[:regapp][:app_dir]}/"
 command "ruby register.rb"
end




