from __future__ import unicode_literals
from django.db import models

from django.utils import timezone
from django.utils.translation import ugettext_lazy as _
from django.contrib.sites.models import Site
from django.contrib.sites.managers import CurrentSiteManager
from django.utils.encoding import python_2_unicode_compatible


from django.contrib.auth.models import (
    BaseUserManager, AbstractBaseUser, PermissionsMixin
)



def get_user_display_name(user):
	return user.first_name


class EmailUserManager(BaseUserManager):

    def create_user(self, email, first_name, last_name, password=None):
        if not email:
            raise ValueError('Users must have an email')

        if not first_name:
            raise ValueError('Users must supply a first name')

        if not last_name:
            raise ValueError('Users must supply a last name')

        if not password:
            raise ValueError('Users must have a password')

        user = self.model(
            email=self.normalize_email(email),
            first_name=first_name,
            last_name=last_name
        )

        user.set_password(password)

        user.save(using=self._db)
        return user

    def create_superuser(self, email, first_name, last_name,  password):
        user = self.create_user(email, first_name, last_name,  password)
        user.is_staff = True
        user.is_superuser = True
        user.save(using=self._db)

class EmailUser(AbstractBaseUser, PermissionsMixin):
    '''
    Just the same user as default, but we use email instead of username
    '''
    email = models.EmailField(
        verbose_name=_("email address"),
        unique=True,
    )

    first_name = models.CharField(max_length=48)
    last_name = models.CharField(max_length=48)

    is_staff = models.BooleanField(
        _('staff status'),
        default=False,
        help_text=_('Designates whether the user can log into this admin site.'),
    )
    is_active = models.BooleanField(
        _('active'),
        default=True,
        help_text=_(
            'Designates whether this user should be treated as active. '
            'Unselect this instead of deleting accounts.'
        ),
    )
    date_joined = models.DateTimeField(_('date joined'), default=timezone.now)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    objects = EmailUserManager()

    def get_full_name(self):
        return " ".join([self.first_name, self.last_name])

    def get_short_name(self):
        return self.email

    def __unicode__(self):
        return self.email
