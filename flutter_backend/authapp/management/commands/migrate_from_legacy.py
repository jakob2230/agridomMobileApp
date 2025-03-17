from django.db import models
from django.core.management.base import BaseCommand
from flutter_backend.authapp.models import CustomerUser, Company, Position

class UsersLegacy(models.Model):  # Class name MUST match the import
    employee_id = models.CharField(unique=True, max_length=6)
    first_name = models.CharField(max_length=100, blank=True, null=True)
    surname = models.CharField(max_length=100, blank=True, null=True)
    company = models.CharField(max_length=100, blank=True, null=True)
    position = models.CharField(max_length=100, blank=True, null=True)
    birth_date = models.DateField(blank=True, null=True)
    date_hired = models.DateField(blank=True, null=True)
    pin = models.CharField(max_length=4, blank=True, null=True)
    status = models.IntegerField(blank=True, null=True)
    preset_name = models.CharField(max_length=100, blank=True, null=True)

    class Meta:
        managed = False  # Ensure this line exists
        db_table = 'users'  # Maps to your legacy table

class Command(BaseCommand):
    help = 'Migrates users from legacy database to new structure'

    def handle(self, *args, **options):
        for legacy_user in UsersLegacy.objects.all():
            # Create or get company
            if legacy_user.company:
                company, _ = Company.objects.get_or_create(name=legacy_user.company)
            else:
                company = None

            # Create or get position
            if legacy_user.position:
                position, _ = Position.objects.get_or_create(title=legacy_user.position)
            else:
                position = None

            # Create new user
            CustomerUser.objects.create(
                employee_id=legacy_user.employee_id,
                first_name=legacy_user.first_name,
                surname=legacy_user.surname,
                company=company,
                position=position,
                birth_date=legacy_user.birth_date,
                date_hired=legacy_user.date_hired,
                pin=legacy_user.pin,
                preset_name=legacy_user.preset_name,
                is_active=bool(legacy_user.status)
            )
            
            self.stdout.write(
                self.style.SUCCESS(f'Successfully migrated user {legacy_user.employee_id}')
            )