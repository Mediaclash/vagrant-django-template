from .base import *

DEBUG = False

COMPRESS_ENABLED = True



try:
	from .local import *
except ImportError:
	pass
