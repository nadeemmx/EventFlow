from setuptools import setup, find_packages

setup(
    name="EventFlow",
    version="1.0.0",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "Django==4.2.16",
        "djangorestframework==3.15.2",
        "djangorestframework-simplejwt==5.3.1",
        "mysqlclient==2.2.4",
        "python-decouple==3.8",
        "reportlab==4.2.0",
        "openpyxl==3.1.5",
        "Pillow==10.4.0",
        "django-cors-headers==4.4.0",
        "python-dateutil==2.9.0",
        "django-filter==24.3",
        "whitenoise==6.7.0",
    ],
)
