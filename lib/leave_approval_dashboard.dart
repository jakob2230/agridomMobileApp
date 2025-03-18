import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LeaveApprovalDashboard extends StatefulWidget {
  final Map<String, dynamic>? newLeaveRequest;
  final String employeeId;
  const LeaveApprovalDashboard({
    Key? key,
    this.newLeaveRequest,
    required this.employeeId,
  }) : super(key: key);

  @override
  _LeaveApprovalDashboardState createState() => _LeaveApprovalDashboardState();
}

class _LeaveApprovalDashboardState extends State<LeaveApprovalDashboard> {
  List<Map<String, dynamic>> leaveApplications = [];

  @override
  void initState() {
    super.initState();
    // If a new leave request is passed, display it along with the rest from the API.
    // You could also merge the newLeaveRequest into the fetched list.
    if (widget.newLeaveRequest != null) {
      leaveApplications = [widget.newLeaveRequest!];
    }
    fetchLeaveApplications();
  }

  Future<void> fetchLeaveApplications() async {
    try {
      // Use the employeeId as a query parameter so that only this user's leave requests are returned.
      final response = await http.get(Uri.parse(
          "http://127.0.0.1:8000/api/leave-requests/?employee_id=${widget.employeeId}"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          leaveApplications = List<Map<String, dynamic>>.from(data["leaveRequests"]);
        });
      } else {
        // Optionally handle errors.
      }
    } catch (e) {
      // Optionally handle errors.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Approval Status'),
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with logo and title.
            Center(
              child: Column(
                children: [
                  Image.asset('images/SFgroup.png', height: 75),
                  const SizedBox(height: 10),
                  const Text(
                    'Your Leave Applications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Display leave requests in a list.
            Expanded(
              child: leaveApplications.isNotEmpty
                  ? ListView.builder(
                      itemCount: leaveApplications.length,
                      itemBuilder: (context, index) {
                        final app = leaveApplications[index];
                        Color statusColor = app['status'] == 'Approved'
                            ? Colors.green
                            : (app['status'] == 'Rejected' ? Colors.red : Colors.orange);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(app['leaveType'] ?? 'N/A'),
                            subtitle: Text('Dates: ${app['startDate']} - ${app['endDate']}'),
                            trailing: Text(
                              app['status'] ?? 'Pending',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(child: Text("No pending leave requests.")),
            ),
          ],
        ),
      ),
    );
  }
}