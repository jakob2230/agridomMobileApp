# authapp/models.py
from django.db import models
from django.core.validators import MinLengthValidator
from django.utils import timezone


class Company(models.Model):
    name = models.CharField(max_length=255)
    # Add other fields as needed

    def __str__(self):
        return self.name
    
    class Meta:
        db_table = "django_companies"

class Position(models.Model):
    title = models.CharField(max_length=255)
    # Add other fields as needed

    def __str__(self):
        return self.title
    
    class Meta:
        db_table = "django_positions"

class CustomerUser(models.Model):
    employee_id = models.CharField(unique=True, max_length=6)
    first_name = models.CharField(max_length=100, null=True, blank=True)
    surname = models.CharField(max_length=100, null=True, blank=True)
    company = models.ForeignKey(Company, on_delete=models.SET_NULL, null=True, blank=True)
    position = models.ForeignKey(Position, on_delete=models.SET_NULL, null=True, blank=True)
    birth_date = models.DateField(null=True, blank=True)
    date_hired = models.DateField(null=True, blank=True)
    pin = models.CharField(max_length=4, validators=[MinLengthValidator(4)], null=True, blank=True)
    preset_name = models.CharField(max_length=100, null=True, blank=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    is_guard = models.BooleanField(default=False)
    if_first_login = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)
    last_login = models.DateTimeField(null=True, blank=True)
    leave_credits = models.IntegerField(default=16)
    sick_leave_credits = models.IntegerField(default=10)

    def __str__(self):
        return self.employee_id

    @classmethod
    def authenticate_by_pin(cls, employee_id, pin):
        try:
            user = cls.objects.get(employee_id=employee_id)
            if user.pin == pin:
                return user
            else:
                return None
        except cls.DoesNotExist:
            return None
    
    class Meta:
        db_table = "django_users"

class TimeEntry(models.Model):
    user = models.ForeignKey(CustomerUser, on_delete=models.CASCADE)  # This is the correct field name
    time_in = models.DateTimeField(auto_now_add=True)
    time_out = models.DateTimeField(null=True, blank=True)
    image = models.TextField(null=True, blank=True)  # For storing image path or base64
    location = models.CharField(max_length=255, null=True, blank=True)  # New field for location

    class Meta:
        db_table = 'django_time_entries'

    def __str__(self):
        return f"{self.user.first_name} {self.user.surname} - {self.time_in}"


class LeaveRequest(models.Model):
    PAYMENT_CHOICES = (
    ("with pay", "With Pay"),
    ("w/o pay", "Without Pay"),
    )
    user = models.ForeignKey(CustomerUser, on_delete=models.CASCADE)
    leave_type = models.CharField(max_length=50)
    start_date = models.DateField()
    end_date = models.DateField()
    leave_days = models.IntegerField()
    reason = models.TextField(null=True, blank=True)
    status = models.CharField(max_length=20, default="Pending")
    payment_option = models.CharField(
        max_length=20,
        choices=PAYMENT_CHOICES,
        default="with pay"
    )
    submitted_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.first_name} {self.user.surname} - {self.leave_type} ({self.status})"
    

