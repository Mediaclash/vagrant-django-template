# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
	# Base box to build off, and download URL for when it doesn't exist on the user's system already
	config.vm.box = "ubuntu/trusty32"
	config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-i386-vagrant-disk1.box"

	# As an alternative to precise32, VMs can be built from the 'django-base' box as defined at
	# https://github.com/torchbox/vagrant-django-base , which has more of the necessary server config
	# baked in and thus takes less time to initialise. To go down this route, you will need to build
	# and host django-base.box yourself, and substitute your own URL below.
	#config.vm.box = "django-base-v2.2"
	#config.vm.box_url = "http://vmimages.torchbox.com/django-base-v2.2.box"  # Torchbox-internal URL to django-base.box

	# Boot with a GUI so you can see the screen. (Default is headless)
	# config.vm.boot_mode = :gui

	# Assign this VM to a host only network IP, allowing you to access it
	# via the IP.
	# config.vm.network "33.33.33.10"

	# Forward a port from the guest to the host, which allows for outside
	# computers to access the VM, whereas host only networking does not.
	# config.vm.network "forwarded_port", guest: 8000, host: 4001

	# forward a port for tomcat as well
	# config.vm.network "forwarded_port", guest: 8080, host: 9092

	# VirtualBox setting
	  # Use all CPU cores and 1/4 system memory
	  config.vm.provider "virtualbox" do |v|
	      host = RbConfig::CONFIG['host_os']

	      # Give VM 1/8 system memory & access to all cpu cores on the host
	      if host =~ /darwin/
	          cpus = `sysctl -n hw.ncpu`.to_i
	          # sysctl returns Bytes and we need to convert to MB
	          mem = `sysctl -n hw.memsize`.to_i / 1024 / 1024 / 8
	      elsif host =~ /linux/
	          cpus = `nproc`.to_i
	          # meminfo shows KB and we need to convert to MB
	          mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024 / 8
	      else # sorry Windows folks, I can't help you
	          cpus = 2
	          mem = 1024
	      end

	      v.customize ["modifyvm", :id, "--memory", mem]
	      v.customize ["modifyvm", :id, "--cpus", cpus]
	  end

		# Share an additional folder to the guest VM. The first argument is
		# an identifier, the second is the path on the guest to mount the
		# folder, and the third is the path on the host to the actual folder.
		config.vm.synced_folder ".", "/var/www/{{ project_name }}/{{ project_name }}"

		# Enable provisioning with a shell script.
		config.vm.provision :shell, :path => "etc/install/install.sh", :args => "{{ project_name }}"


		# Host Manager
	  config.hostmanager.enabled = true
	  config.hostmanager.manage_host = true
	  config.hostmanager.ignore_private_ip = false
	  config.hostmanager.include_offline = true
	  config.vm.define '{{ project_name }}.dev' do |node|
	      node.vm.hostname = '{{ project_name }}.dev'
	      node.vm.network :private_network, ip: '192.168.98.100'
	      node.hostmanager.aliases = %w({{ project_name }}.dev)
	  end
end
