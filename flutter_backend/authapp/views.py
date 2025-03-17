import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.cache import never_cache
from django.contrib.auth import login
from .models import CustomerUser, LeaveRequest
from django.utils import timezone
from .models import CustomerUser, TimeEntry
import logging
from .models import TimeEntry
from django.utils import timezone


logger = logging.getLogger(__name__)

@csrf_exempt
@never_cache
def login_view(request):
    if request.method != "POST":
        return JsonResponse({"success": False, "message": "Only POST requests are allowed"})
    
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"success": False, "message": "Invalid JSON"})
    
    # Retrieve credentials from request body using keys 'username' and 'password'
    employee_id = data.get("username")
    pin = data.get("password")
    
    if not employee_id or not pin:
        return JsonResponse({"success": False, "message": "Missing credentials"})
    
    try:
        # Check if the user exists and is active
        user = CustomerUser.objects.get(employee_id=employee_id)
        if not user.is_active:
            return JsonResponse({"success": False, "message": "This account is inactive"})
        
        # Try to authenticate using the provided PIN
        auth_result = CustomerUser.authenticate_by_pin(employee_id, pin)
        if (auth_result):
            user = auth_result if isinstance(auth_result, CustomerUser) else auth_result["user"]
            login(request, user)  # Establish the session if needed

            # Return a JSON response with the user's name included
            return JsonResponse({
                "success": True,
                "message": "Login successful",
                "redirect": "maindash",
                "first_name": user.first_name,
                "surname": user.surname,
            })
        else:
            return JsonResponse({"success": False, "message": "Incorrect PIN"})
    except CustomerUser.DoesNotExist:
        return JsonResponse({"success": False, "message": "Employee ID not found"})


@csrf_exempt
def time_in_view(request):
    if request.method != "POST":
        return JsonResponse({"success": False, "message": "Only POST requests are allowed"})
    
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"success": False, "message": "Invalid JSON"})
    
    employee_id = data.get("employee_id")
    image_path = data.get("image")
    location = data.get("location")  # New: get location from request

    try:
        user = CustomerUser.objects.get(employee_id=employee_id)
        # Create a new time entry including location
        entry = TimeEntry.objects.create(
            user=user, 
            time_in=timezone.now(), 
            image=image_path,
            location=location
        )
        return JsonResponse({
            "success": True,
            "message": "Time in recorded",
            "entry": {
                "name": f"{user.first_name} {user.surname}",
                "time_in": entry.time_in.strftime("%Y-%m-%d %I:%M:%S %p"),
                "time_out": "Not Yet Out",
                "location": entry.location if entry.location else "N/A"
            }
        })
    except CustomerUser.DoesNotExist:
        return JsonResponse({"success": False, "message": "User not found"})

@csrf_exempt
@never_cache
def time_out_view(request):
    if request.method != "POST":
        return JsonResponse({"success": False, "message": "Only POST requests are allowed"})
    
    try:
        data = json.loads(request.body)
        employee_id = data.get("employee_id")
        
        if not employee_id:
            return JsonResponse({"success": False, "message": "Employee ID is required"})

        # Find today's time entry for this employee
        today = timezone.now().date()
        time_entry = TimeEntry.objects.filter(
            user__employee_id=employee_id,  # Changed from employee to user
            time_in__date=today,
            time_out__isnull=True
        ).first()

        if not time_entry:
            return JsonResponse({
                "success": False, 
                "message": "No active time entry found for today"
            })

        # Record time out
        time_entry.time_out = timezone.now()
        time_entry.save()

        return JsonResponse({
            "success": True,
            "message": "Time out recorded successfully",
            "time_out": time_entry.time_out.strftime('%Y-%m-%d %H:%M:%S')
        })

    except Exception as e:
        print(f"Error in time_out_view: {str(e)}")  # Add debug print
        return JsonResponse({"success": False, "message": str(e)})

def attendance_list_view(request):
    try:
        today = timezone.now().date()
        entries = TimeEntry.objects.filter(time_in__date=today).order_by("-time_in")
        data = []
        for entry in entries:
            data.append({
                "name": f"{entry.user.first_name} {entry.user.surname}",
                "time_in": entry.time_in.strftime("%Y-%m-%d %I:%M:%S %p"),
                "time_out": entry.time_out.strftime("%Y-%m-%d %I:%M:%S %p") if entry.time_out else "Not Yet Out",
                "location": entry.location if entry.location else "N/A",
            })
        return JsonResponse({"success": True, "attendance": data})
    except Exception as e:
        logger.error(f"Error fetching attendance: {e}")
        return JsonResponse({"success": False, "message": "Error fetching attendance"})


@csrf_exempt
def submit_leave_request(request):
    if request.method != "POST":
        return JsonResponse({"success": False, "message": "Only POST requests are allowed"})
    
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"success": False, "message": "Invalid JSON"})
    
    employee_id = data.get("employee_id")
    leave_type = data.get("leaveType")
    start_date = data.get("startDate")
    end_date = data.get("endDate")
    leave_days = data.get("leaveDays")
    reason = data.get("reason")

    if not all([employee_id, leave_type, start_date, end_date, leave_days]):
        return JsonResponse({"success": False, "message": "Missing required fields"})
    
    try:
        user = CustomerUser.objects.get(employee_id=employee_id)
        # Create the leave request and save it with default "Pending" status
        leave_request = LeaveRequest.objects.create(
            user=user,
            leave_type=leave_type,
            start_date=start_date,
            end_date=end_date,
            leave_days=leave_days,
            reason=reason,
            status="Pending"
        )
        return JsonResponse({"success": True, "message": "Leave request submitted successfully!"})
    except CustomerUser.DoesNotExist:
        return JsonResponse({"success": False, "message": "User not found"})
    except Exception as e:
        return JsonResponse({"success": False, "message": str(e)})