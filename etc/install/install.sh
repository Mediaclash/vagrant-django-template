#!/bin/bash

# Script to set up a Django project on Vagrant.

# Installation settings

PROJECT_NAME=$1

DB_NAME=$PROJECT_NAME
VIRTUALENV_NAME=$PROJECT_NAME

PROJECT_DIR=/var/www/$PROJECT_NAME/$PROJECT_NAME
VIRTUALENV_DIR=/var/www/$PROJECT_NAME
LOCAL_SETTINGS_PATH="/$PROJECT_NAME/settings/local.py"

# Install essential packages from Apt
apt-get update -y
# Python dev packages
apt-get install -y build-essential python python-dev
# python-setuptools being installed manually
wget https://raw.githubusercontent.com/pypa/setuptools/bootstrap/ez_setup.py -O - | python
# Dependencies for image processing with Pillow (drop-in replacement for PIL)
# supporting: jpeg, tiff, png, freetype, littlecms
# (pip install pillow to get pillow itself, it is not in requirements.txt)
apt-get install -y libjpeg-dev libtiff-dev zlib1g-dev libfreetype6-dev liblcms2-dev
# Git (we'd rather avoid people keeping credentials for git commits in the repo, but sometimes we need it for pip requirements that aren't in PyPI)
apt-get install -y git

apt-get install -y pngquant


# Postgresql
if ! command -v psql; then
    apt-get install -y postgresql libpq-dev
    # Create vagrant pgsql superuser
    su - postgres -c "createuser -s vagrant"
    # create a user for our project
    su - postgres -c "createuser -s $PROJECT_NAME"
fi

# virtualenv global setup
if ! command -v pip; then
    easy_install -U pip
fi
if [[ ! -f /usr/local/bin/virtualenv ]]; then
    pip install virtualenv virtualenvwrapper stevedore virtualenv-clone
fi

# bash environment global setup
cp -p $PROJECT_DIR/etc/install/bashrc /home/vagrant/.bashrc

# ---

# postgresql setup for project
su - vagrant -c "createdb $DB_NAME"

# make sure we own the virtualenv folder
sudo chown vagrant:vagrant -R $VIRTUALENV_DIR

# virtualenv setup for project
su - vagrant -c "/usr/local/bin/virtualenv $VIRTUALENV_DIR && \
    echo $PROJECT_DIR > $VIRTUALENV_DIR/.project && \
    $VIRTUALENV_DIR/bin/pip install -r $PROJECT_DIR/requirements.txt"

echo "source $VIRTUALENV_DIR/bin/activate && cd $PROJECT_DIR" >> /home/vagrant/.bashrc

# Set execute permissions on manage.py, as they get lost if we build from a zip file
chmod a+x $PROJECT_DIR/manage.py

# Django project setup
su - vagrant -c "$VIRTUALENV_DIR/bin/python $PROJECT_DIR/manage.py migrate"


# Add settings/local.py to gitignore
if ! grep -Fqx $LOCAL_SETTINGS_PATH $PROJECT_DIR/.gitignore
then
    echo $LOCAL_SETTINGS_PATH >> $PROJECT_DIR/.gitignore
fi

apt-get install -y nginx

ln -fs $PROJECT_DIR/etc/deploy/$PROJECT_NAME.nginx.conf /etc/nginx/sites-enabled/$PROJECT_NAME

nginx -s reload

su - vagrant -c "$VIRTUALENV_DIR/bin/python $PROJECT_DIR/manage.py create_default_admin"

echo "Done!"

