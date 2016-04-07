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
wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -O - | python
# Dependencies for image processing with Pillow (drop-in replacement for PIL)
# supporting: jpeg, tiff, png, freetype, littlecms
# (pip install pillow to get pillow itself, it is not in requirements.txt)
apt-get install -y libjpeg-dev libtiff-dev zlib1g-dev libfreetype6-dev liblcms2-dev
# Git (we'd rather avoid people keeping credentials for git commits in the repo, but sometimes we need it for pip requirements that aren't in PyPI)
apt-get install -y git

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

# setup JRE for solr / tomcat
apt-get -y install python-software-properties
add-apt-repository -y ppa:webupd8team/java
apt-get -q -y update

echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

apt-get -y install oracle-java7-installer

echo -e "nnJAVA_HOME=/usr/lib/jvm/java-7-oracle" >> /etc/environment;
export JAVA_HOME=/usr/lib/jvm/java-7-oracle/

# Check for md5sum & tar
program_exists md5sum
program_exists tar

# Determine which package manager is available
echo -n "Checking for a supported package manager..."
if command -v apt-get 2>/dev/null; then
  # Debian, Ubuntu, Linux Mint
  PACKAGE_MAN=apt-get
elif command -v yum 2>/dev/null; then
  # Red Hat, CentOS
  PACKAGE_MAN=yum
else
  echo "Not Found" >&2
  echo "Supported package managers: apt-get, yum" >&2
  exit 1
fi

echo "Installing Tomcat 6 and curl"
if [ "$PACKAGE_MAN" = "apt-get" ]; then
  apt-get update
  apt-get install -y tomcat7 tomcat7-admin tomcat7-common tomcat7-user curl
  # Apt-get starts tomcat
elif [ "$PACKAGE_MAN" = "yum" ]; then
  yum install -y tomcat7 tomcat7-webapps tomcat7-admin-webapps curl
  # Set tomcat to start on boot
  chkconfig tomcat7 on
  # Start tomcat
  service tomcat7 start
fi

# Check for Java >= 1.6.0
echo -n "Checking Java version >= 1.6.0..."
JAVA_VER=$(java -version 2>&1 | sed 's/java version "\(.*\)\.\(.*\)\..*"/\1\2/; 1q')
if [ $JAVA_VER -lt 16 ]; then
  if [ "$PACKAGE_MAN" = "apt-get" ]; then
    echo "Failed" >&2
    echo "Apache Solr requires Java 1.6.0 or greater." >&2
    exit 1
  elif [ "$PACKAGE_MAN" = "yum" ]; then
    echo "Upgrading"
    # Install Java 1.7.0; it should become the default
    yum install -y java-1.7.0
    service tomcat7 restart
    echo -n "Rechecking Java version >= 1.6.0..."
    JAVA_VER=$(java -version 2>&1 | sed 's/java version "\(.*\)\.\(.*\)\..*"/\1\2/; 1q')
    if [ $JAVA_VER -lt 16 ]; then
      echo "Failed" >&2
      echo "Apache Solr requires Java 1.6.0 or greater." >&2
      exit 1
    fi
    echo "Ok"
  fi
else
  echo "Ok"
fi
TOMCAT_PORT=8080
TOMCAT_DIR=/usr/share/tomcat7
TOMCAT_WEBAPP_DIR=$TOMCAT_DIR/webapps
TOMCAT_CATALINA_DIR=/etc/tomcat7/Catalina/localhost
SOLR_INSTALL_DIR=/usr/share/solr4
APACHE_CLOSER_URL=http://www.apache.org/dyn/closer.cgi
APACHE_BACKUP_URL=http://www.us.apache.org/dist/lucene/solr
DOWNLOAD_DIR=/root
TMP_DIR=/tmp

echo Locating an Apache Download Mirror
# Get the mirror list, display only lines where http is in the content,
# get the first match result.
MIRROR=$(curl -s $APACHE_CLOSER_URL \
         | grep '>http' | grep -o -m 1 'http://[^" ]*/' | head -n1)
echo Using: $MIRROR

echo Get HTML of the lucene/solr directory
HTML_LUCENE_SOLR=$(curl -s ${MIRROR}lucene/solr/)

# Get the most recent 4.x.x version number.
#SOLR_VERSION=$(echo $HTML_LUCENE_SOLR | grep -o '4\.[^/ ]*' | tail -n1)
#if [ -z "$SOLR_VERSION" ]; then
#  echo "ERROR: Apache Solr 4.x.x archive cannot be found." >&2
#  exit 1
#fi

SOLR_VERSION=4.10.4

echo Found version: $SOLR_VERSION

#http://mirrors.muzzy.org.uk/apache/lucene/solr/4.10.4/solr-4.10.4.tgz

# Convert the version string into an array
ARRAY_SOLR_VERSION=(${SOLR_VERSION//./ })

# Check the minor version (Still needed?)
#if [ ${ARRAY_SOLR_VERSION[1]} != 6 ]; then
#  echo ERROR: Only Solr 4.6.x or greater is supported by this script.
#  exit 1;
#fi

# Construct a filename and download the file to $DOWNLOAD_DIR
SOLR_FILENAME=solr-$SOLR_VERSION.tgz
SOLR_FILE_URL=${MIRROR}lucene/solr/$SOLR_VERSION/$SOLR_FILENAME

if [ -f "$DOWNLOAD_DIR/$SOLR_FILENAME" ];
then
  echo Using cached copy of Solr at: $DOWNLOAD_DIR/$SOLR_FILENAME
else
  echo Downloading: $SOLR_FILE_URL
  curl -o $DOWNLOAD_DIR/$SOLR_FILENAME $SOLR_FILE_URL
fi

# Verify the download
SOLR_MD5_URL=$APACHE_BACKUP_URL/$SOLR_VERSION/$SOLR_FILENAME.md5
echo
echo Downloading MD5 checksum: $SOLR_MD5_URL
curl -o $DOWNLOAD_DIR/$SOLR_FILENAME.md5 $SOLR_MD5_URL
echo Verifying the MD5 checksum
(cd $DOWNLOAD_DIR; md5sum -c $SOLR_FILENAME.md5)

echo Uncompressing the file
(cd $TMP_DIR; tar zxf $DOWNLOAD_DIR/$SOLR_FILENAME)

echo Installing Solr as a Tomcat webapp
SOLR_SRC_DIR=$TMP_DIR/solr-$SOLR_VERSION
mkdir -p $TOMCAT_WEBAPP_DIR
cp $SOLR_SRC_DIR/dist/solr-$SOLR_VERSION.war $TOMCAT_WEBAPP_DIR/solr4.war

# Copy the multicore files and change ownership
mkdir -p $SOLR_INSTALL_DIR/multicore
cp -R $SOLR_SRC_DIR/example/multicore $SOLR_INSTALL_DIR/
# Debian & Red Hat use different tomcat users/groups
# TODO: Detect correct user/group
chown -R tomcat7:tomcat7 $SOLR_INSTALL_DIR

# Setup the config file for Tomcat
cat > $TOMCAT_CATALINA_DIR/solr4.xml << EOF
<Context docBase="$TOMCAT_WEBAPP_DIR/solr4.war" debug="0" privileged="true" allowLinking="true" crossContext="true">
    <Environment name="solr/home" type="java.lang.String" value="$SOLR_INSTALL_DIR/multicore" override="true" />
</Context>
EOF

# Setup log4j
# see: http://wiki.apache.org/solr/SolrLogging#Using_the_example_logging_setup_in_containers_other_than_Jetty
cp $SOLR_SRC_DIR/example/lib/ext/* $TOMCAT_DIR/lib/
cp $SOLR_SRC_DIR/example/resources/log4j.properties $TOMCAT_DIR/lib/

echo "Restarting Tomcat to enable Solr"
service tomcat7 restart
