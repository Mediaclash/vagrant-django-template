from fabric.api import cd, env, run, sudo, task, execute
from fabtools.vagrant import vagrant
from fabtools import require
import fabtools
import fabric

from fabric.contrib.files import exists, append, comment, contains
from fabric.contrib.console import confirm

from fabric.colors import blue, cyan, green, red, blue

import os

@task
def default():
    '''
    Sets up the default env variables
    '''
    env.base_path = '/var/www/{{ project_name }}/{{ project_name }}'
    env.virtualenv_path = '/var/www/{{ project_name }}'
    env.db_name = '{{ project_name }}'

default()

@task
def staging():
    '''
    Sets up the staging env variables
    '''
    pass

@task
def live():
    '''
    Sets up live env variables
    '''
    pass

@task
def devserver(settings_file="{{ project_name }}.settings"):
    '''
    Start the development server
    '''
    with fabtools.python.virtualenv(env.virtualenv_path), cd(env.base_path):
        run('python manage.py runserver 0.0.0.0:8000 --settings=%(settings_file)s' % locals())
