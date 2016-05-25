# Mediaclash Base CMS Project Template

This is the Mediaclash 'blank' CMS template for new projects. It's based on the torchbox vagrant django template from https://github.com/torchbox/vagrant-django-template

## Getting Started
You'll need to install django 1.9+ on your development machine, either globally or inside a virtualenv. You'll also need fabric and fabtools installed
```sh
pip install django>=1.9
pip install fabric fabtools
```

You also need to have vagrant host manager installed

```sh
vagrant plugin install vagrant-host-manager
```

Next, run the standard django startproject command, with this repository as the base template:

```sh
cd /my-development-folder/
django-admin.py startproject --template https://github.com/mediaclash/vagrant-django-template/zipball/master --name=Vagrantfile -e py,ini,conf myproject
cd myproject
vagrant up
```

or if you have cloned this repo already

```sh
django-admin.py startproject --template=. --name=Vagrantfile -e py,conf,ini myproject /my_project_folder
cd /my_project_folder
vagrant up
```


This process will:
  - Download and setup a vagrant VM based on ubuntu 14.4 32-bit
  - Update packages and install development dependencies
  - Install and setup a postgres database in the VM, with access for the vagrant user
  - Create shared folders for the project in /var/www/<project_name>/<project_name> ( in the VM )
  - Create a virtualenv in /var/www/<project_name>/
  - Install django, django cms, easy thumbnails, compressor, haystack and other useful bits.
  - Install circus and nginx for a fast dev server.
  - Alter the default user model to use emails for login instead of username, and make first_name and last_name required.
  - Bind the VM to the private network
  - Update your hosts file, mapping the vm to <project_name>.dev

This process will not create a superuser account, you need to do this yourself:

```sh
vagrant ssh
python manage.py createsuperuser
```

There is also a simple fabric file, have a look at that for more info. 

```sh
fab vagrant devserver
```
