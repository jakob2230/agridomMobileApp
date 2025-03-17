from django.urls import path
from django.contrib import admin
from django.views.generic import RedirectView
from .authapp import views


urlpatterns = [
    # Redirect root to your Flutter app's static page
    path('', RedirectView.as_view(url='/static/flutter_app/index.html', permanent=False)),
    
    # Define the API endpoint for login
    path('api/login/', views.login_view, name='api_login'),

    # New endpoints for attendance
    path('api/time-in/', views.time_in_view, name='api_time_in'),
    path('api/attendance/', views.attendance_list_view, name='api_attendance'),
    path('api/time-out/', views.time_out_view, name='api_time_out'),
    path('api/submit-leave/', views.submit_leave_request, name='api_submit_leave'),
    
    # Admin route
    path('admin/', admin.site.urls),
]















