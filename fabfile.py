from fabric.api import cd, env, run, sudo, task, execute
from fabtools.vagrant import vagrant
from fabtools import require
import fabtools
import fabric

from fabric.contrib.files import exists, append, comment, contains
from fabric.contrib.console import confirm

from fabric.colors import blue, cyan, green, red, blue
from datetime import datetime
import os

PROJECT_NAME = "{{ project_name }}"


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
    #env.hosts = [staging_host,]
    #env.deploy_user = 'deploy_user'
    pass

@task
def live():
    '''
    Sets up live env variables
    '''
    #env.hosts = [web1, web2]
    pass

@task
def devserver(settings_file="{{ project_name }}.settings"):
    '''
    Start the development server
    '''
    with fabtools.python.virtualenv(env.virtualenv_path), cd(env.base_path):
        run('python manage.py runserver 0.0.0.0:8000 --settings=%(settings_file)s' % locals())

@task
def circus():
    with fabtools.python.virtualenv(env.virtualenv_path), cd(env.base_path):
        run('circusd circus.ini')

@task
def deploy(commit_hash=None):
    commit_hash = commit_hash or get_current_commit()
    with cd(env.base_path), fabtools.python.virtualenv(env.virtualenv_path):
        sudo('git fetch', user=env.deploy_user)
        sudo('git reset --hard %(commit_hash)s' % locals(), user=env.deploy_user)
        venv_path = env.virtualenv_path
        proj_path = env.base_path
        suffix = env.settings_suffix or "dev"
        settings_file = "{{ project_name }}.settings.%(suffix)s" % locals()
        sudo('%(venv_path)s/bin/pip install -r %(proj_path)s/requirements.txt' % locals(), user=env.deploy_user)
        sudo('%(venv_path)s/bin/python %(proj_path)s/manage.py migrate --settings=%(settings_file)s' % locals(), user=env.deploy_user)
        sudo('%(venv_path)s/bin/python %(proj_path)s/manage.py collectstatic --noinput --settings=%(settings_file)s' % locals(), user=env.deploy_user)
        with settings(warn_only=True):
            sudo('%(venv_path)s/bin/python %(proj_path)s/manage.py compress --settings=%(settings_file)s' % locals(), user=env.deploy_user)
        
        if env.reset_command:
            sudo(env.reset_command, user=env.deploy_user)
        with settings(warn_only=True):
            sudo('%(venv_path)s/bin/python %(proj_path)s/manage.py register_deploy %(commit_hash)s --settings=%(settings_file)s' % locals(), user=env.deploy_user)


@task
def switch():
    pass


## ----- utilities ----- ##

def get_current_commit():
    return local("git log -n 1 --format=%H", capture=True)
