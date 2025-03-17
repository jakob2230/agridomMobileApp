// leave_approval_dashboard.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LeaveApprovalDashboard extends StatefulWidget {
  const LeaveApprovalDashboard({super.key});

  @override
  _LeaveApprovalDashboardState createState() => _LeaveApprovalDashboardState();
}

class _LeaveApprovalDashboardState extends State<LeaveApprovalDashboard> {
  List<Map<String, dynamic>> leaveApplications = [];

  @override
  void initState() {
    super.initState();
    fetchLeaveApplications();
  }

  Future<void> fetchLeaveApplications() async {
    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/api/leave-requests/"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          leaveApplications = List<Map<String, dynamic>>.from(data["leaveRequests"]);
        });
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle error
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
            // Header with logo and title
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
            // List of leave applications with their status
            Expanded(
              child: ListView.builder(
                itemCount: leaveApplications.length,
                itemBuilder: (context, index) {
                  final app = leaveApplications[index];
                  Color statusColor = app['status'] == 'Approved'
                      ? Colors.green
                      : (app['status'] == 'Rejected' ? Colors.red : Colors.orange);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(app['leaveType']),
                      subtitle: Text('Dates: ${app['startDate']} - ${app['endDate']}'),
                      trailing: Text(
                        app['status'],
                        style: TextStyle(
                            color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
