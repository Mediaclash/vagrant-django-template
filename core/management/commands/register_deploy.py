from django.core.management.base import BaseCommand
from django.conf import settings

from opbeat.conf import defaults

import requests


RELEASES_API_PATH = '{}/api/v1/organizations/{}/apps/{}/releases/'

class Command(BaseCommand):
    help = "Log a deployment to opbeat"

    def add_arguments(self, parser):
        parser.add_argument('revision')

    def handle(self, *args, **options):
        url = RELEASES_API_PATH.format(
            defaults.SERVERS[0],
            settings.OPBEAT['ORGANIZATION_ID'],
            settings.OPBEAT['APP_ID'],
        )

        headers = {
            'Authorization': 'Bearer {}'.format(
                settings.OPBEAT['SECRET_TOKEN']),
        }

        data = {
            'rev': options['revision'],
            'branch': 'master',
            'status': 'completed',
        }

        requests.post(url, data=data, headers=headers)
