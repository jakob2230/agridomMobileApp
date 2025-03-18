import json
import logging
from datetime import datetime
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.cache import never_cache
from django.contrib.auth import login
from django.utils import timezone
from .models import CustomerUser, LeaveRequest, TimeEntry

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
    
    employee_id = data.get("username")
    pin = data.get("password")
    
    if not employee_id or not pin:
        return JsonResponse({"success": False, "message": "Missing credentials"})
    
    try:
        user = CustomerUser.objects.get(employee_id=employee_id)
        if not user.is_active:
            return JsonResponse({"success": False, "message": "This account is inactive"})
        
        auth_result = CustomerUser.authenticate_by_pin(employee_id, pin)
        if auth_result:
            user = auth_result if isinstance(auth_result, CustomerUser) else auth_result["user"]
            login(request, user)
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
    location = data.get("location")

    try:
        user = CustomerUser.objects.get(employee_id=employee_id)
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

        today = timezone.now().date()
        time_entry = TimeEntry.objects.filter(
            user__employee_id=employee_id,
            time_in__date=today,
            time_out__isnull=True
        ).first()

        if not time_entry:
            return JsonResponse({
                "success": False, 
                "message": "No active time entry found for today"
            })

        time_entry.time_out = timezone.now()
        time_entry.save()

        return JsonResponse({
            "success": True,
            "message": "Time out recorded successfully",
            "time_out": time_entry.time_out.strftime('%Y-%m-%d %H:%M:%S')
        })

    except Exception as e:
        logger.error(f"Error in time_out_view: {str(e)}")
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
    start_date_str = data.get("startDate")
    end_date_str = data.get("endDate")
    leave_days = data.get("leaveDays")
    reason = data.get("reason")
    payment_option = data.get("payment_option", "with pay")

    if not all([employee_id, leave_type, start_date_str, end_date_str, leave_days]):
        return JsonResponse({"success": False, "message": "Missing required fields"})
    
    try:
        start_date_obj = datetime.strptime(start_date_str, "%Y-%m-%d").date()
        end_date_obj = datetime.strptime(end_date_str, "%Y-%m-%d").date()
    except Exception as e:
        return JsonResponse({"success": False, "message": "Invalid date format. Use YYYY-MM-DD."})
    
    try:
        user = CustomerUser.objects.get(employee_id=employee_id)
        
        # Check if the user has sufficient credits
        if leave_type.lower() == "sick leave":
            if user.sick_leave_credits < 1:
                return JsonResponse({"success": False, "message": "Insufficient sick leave credits."})
        else:
            if user.leave_credits < 1:
                return JsonResponse({"success": False, "message": "Insufficient leave credits."})
        
        # Deduct 1 credit per submission based on the leave type
        if leave_type.lower() == "sick leave":
            user.sick_leave_credits -= 1
        else:
            user.leave_credits -= 1
        user.save()
        
        leave_request = LeaveRequest.objects.create(
            user=user,
            leave_type=leave_type,
            start_date=start_date_obj,
            end_date=end_date_obj,
            leave_days=leave_days,
            reason=reason,
            status="Pending",
            payment_option=payment_option
        )
        return JsonResponse({
            "success": True,
            "message": "Leave request submitted successfully!",
            "leaveRequest": {
                "leaveType": leave_request.leave_type,
                "startDate": leave_request.start_date.strftime("%Y-%m-%d"),
                "endDate": leave_request.end_date.strftime("%Y-%m-%d"),
                "leaveDays": leave_request.leave_days,
                "reason": leave_request.reason,
                "status": leave_request.status,
                "paymentOption": leave_request.payment_option
            }
        })
    except CustomerUser.DoesNotExist:
        return JsonResponse({"success": False, "message": "User not found"})
    except Exception as e:
        return JsonResponse({"success": False, "message": str(e)})

@csrf_exempt
def leave_requests_view(request):
    if request.method != "GET":
        return JsonResponse({"success": False, "message": "Only GET requests are allowed"})
    try:
        employee_id = request.GET.get("employee_id")
        if employee_id:
            leave_requests = LeaveRequest.objects.filter(user__employee_id=employee_id).order_by("-submitted_at")
        else:
            leave_requests = LeaveRequest.objects.all().order_by("-submitted_at")
        data = []
        for leave in leave_requests:
            data.append({
                "leaveType": leave.leave_type,
                "startDate": leave.start_date.strftime("%Y-%m-%d"),
                "endDate": leave.end_date.strftime("%Y-%m-%d"),
                "leaveDays": leave.leave_days,
                "reason": leave.reason,
                "status": leave.status,
            })
        return JsonResponse({"success": True, "leaveRequests": data})
    except Exception as e:
        return JsonResponse({"success": False, "message": str(e)})