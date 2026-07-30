import os
import sys

# cPanel Passenger WSGI entry point
# This file MUST be in the root of the backend directory

# Add the backend directory to Python path
BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)

# Set Django settings module
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.production")

# Application entry point for Passenger
from config.wsgi import application as application
