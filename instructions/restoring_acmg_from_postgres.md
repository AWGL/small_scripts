## Restore AMCG Database From Postgres Dump

## Restore From Backup

There are two uses of the backups Firstly restore the entire database in case of complete loss and to restore a single or set of objects that were deleted in error.

Take the backup files from the webserver. For the ACMG database these are located at /home/webapps/acmg_backups. One set of files is the media and another is the database.




### Restore backup to local DB

Copy the database
 backup file to the local machine and create a database from the backup file.

```
sudo -u postgres psql

CREATE DATABASE variant_classification_db; # create a databse to load into

GRANT ALL PRIVILEGES ON DATABASE variant_classification_db TO variant_database_user;

\i /home/joseph/Downloads/20220731220201_acmg_db.txt # where 20220731220201_acmg_db.txt is your uncompressed backup file

GRANT ALL ON ALL TABLES IN SCHEMA public to variant_database_user;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public to variant_database_user;

GRANT ALL ON ALL FUNCTIONS IN SCHEMA public to variant_database_user;

```
### Connect Django

Connect the Django instance to the database by editing the settings.py file

```
	DATABASES = {
		'default': {
			'ENGINE': 'django.db.backends.postgresql_psycopg2',
			'NAME': 'variant_classification_db',
		'USER': 'variant_database_user',
		'PASSWORD': password,
		'HOST': 'localhost',
		'PORT': '',
		}
	}

```
Run the server
```
python manage.py runserver

```
Check for the existance of your missing data.

### Export the required model instances

Put the following script in the management commands folder and run it
```
from itertools import chain      

from django.core import serializers
from django.contrib.admin.utils import NestedObjects

from acmg_db.models import  Sample

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction


class Command(BaseCommand):

	help = 'get related objects'



	def handle(self, *args, **options):

		collector = NestedObjects(using="default") # database name
		collector.collect([Sample.objects.get(name='22-2653-22M11205-fetal_anamolies_green-classic_trio')])

		objects = list(chain.from_iterable(collector.data.values()))
		with open("backup_export.json", "w") as f:
			f.write(serializers.serialize("json", objects))

```
This creates a json file with all the related objects for sample 22-2653-22M11205-fetal_anamolies_green-classic_trio e.g. all classifications, answers and comments


### Load data into live DB

First test that the backup restore works on your local machine by deleting the same data as was deleted in the live database and testing the restore there. If that works repeat procedure on live database

```
python manage.py loaddata backup_export.json
```