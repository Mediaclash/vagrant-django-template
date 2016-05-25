from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.conf import settings
import random, string

class Command(BaseCommand):
    help = "Create a superuser with a random password"

    def handle(self, *args, **options):
    	password = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits) for _ in range(12))
    	email = 'admin@{{ project_name }}.dev'
    	User = get_user_model()

    	su = User.objects.create_superuser(
    		first_name='admin', 
    		last_name='user', 
    		email=email,
    		password=password
    	)

    	print('=== Super User Created ===')
    	print('Email: %(email)s' % locals())
    	print('Password: %(password)s' % locals())
    	print('==========================')