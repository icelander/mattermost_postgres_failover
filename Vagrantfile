# -*- mode: ruby -*-
# vi: set ft=ruby :
MATTERMOST_VERSION = '5.25.1'

MATTERMOST_PASSWORD = 'really_secure_password'

GATEWAY_IP = '192.168.33.101'
APP_IPS = ['192.168.33.102', '192.168.33.103']

# Generate 
POSTGRES_ROOT = 'postgres_root_password'

Vagrant.configure("2") do |config|
	config.vm.box = "bento/ubuntu-18.04"

	APP_IPS.each_with_index do |node_ip, i|
		box_hostname = "app#{i}"

		config.vm.define box_hostname do |box|
			box.vm.hostname = box_hostname
			box.vm.network "forwarded_port", guest: 8065, host: "#{i+1}8065".to_i
		    box.vm.network "forwarded_port", guest: 5432, host: "#{i+1}5432".to_i
		    box.vm.network "private_network", ip: node_ip

	        box.vm.provision :shell do |s|
	    	    s.path = 'app_setup.sh'
	    	    s.args   = [MATTERMOST_VERSION, 
	    	                MATTERMOST_PASSWORD,
	    	            	POSTGRES_ROOT]
	        end
		end
	end

	config.vm.define "gateway" do |gateway|
		gateway.vm.network "private_network", ip: GATEWAY_IP
		gateway.vm.network "forwarded_port", guest: 80, host: 8080
		gateway.vm.network "forwarded_port", guest: 9000, host: 9000
		gateway.vm.hostname = 'gateway'

		gateway.vm.provision :shell do |s|
			s.path = 'haproxy_setup.sh'
		end

		gateway.vm.provision :shell do |s|
			s.path = 'bucardo_setup.sh'
		end

		gateway.vm.provision :shell do |s|
			s.path = 'gluster_setup.sh'
		end
	end
end