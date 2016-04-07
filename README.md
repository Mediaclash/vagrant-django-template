# Mediaclash Base CMS Project Template

This is the Mediaclash 'blank' CMS template for new projects. It's based on the torchbox vagrant django template from https://github.com/torchbox/vagrant-django-template

## Getting Started
You'll need to install django 1.9+ on your development machine, either globally or inside a virtualenv. You'll also need fabric and fabtools installed
```sh
pip install django>=1.9
pip install fabric fabtools
```

Next, run the standard django startproject command, with this repository as the base template:

```sh
cd /my-development-folder/
django-admin.py startproject --template https://github.com/mediaclash/vagrant-django-template/zipball/master --name=Vagrantfile myproject
cd myproject
vagrant up
```

This process will:
  - Download and setup a vagrant VM based on ubuntu 14.4 32-bit
  - Update packages and install development dependencies
  - Install and setup a postgres database in the VM, with access for the vagrant user
  - Create shared folders for the project in /var/www/<project_name>/<project_name> ( in the VM )
  - Create a virtualenv in /var/www/<project_name>/
  - Install django, django cms, easy thumbnails, compressor, haystack and other useful bits.
  - Install Apache SOLR for search provision.
  - Forward 2 ports from the VM - 9000 for the django development server, and 9090 for tomcat / solr.

This process will not create a superuser account, you need to do this yourself:

```sh
vagrant ssh
python manage.py createsuperuser
```

There is also a simple fabric file that will just run the development server. Can be expanded based on your needs.

```sh
fab vagrant devserver
```
