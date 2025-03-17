import 'package:flutter/material.dart';
import 'main.dart'; // Ensure that main.dart exports EmployeeLoginPage if needed

// Your Drawer widget
class AppDrawer extends StatelessWidget {
  final String fullName; // Field to hold the user's full name

  const AppDrawer({super.key, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFF44336),
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(color: Color(0xFFF44336)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFFF44336), size: 30),
                  ),
                  const SizedBox(width: 16),
                  // Display the passed fullName here
                  Text(
                    fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            // Leave Approval menu item
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.white),
              title: const Text('Leave approval', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LeaveApprovalDashboard()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text('About', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeLoginPage(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Leave Approval Dashboard widget
class LeaveApprovalDashboard extends StatefulWidget {
  const LeaveApprovalDashboard({super.key});

  @override
  _LeaveApprovalDashboardState createState() => _LeaveApprovalDashboardState();
}

class _LeaveApprovalDashboardState extends State<LeaveApprovalDashboard> {
  // Dummy data representing the user's leave applications
  final List<Map<String, String>> leaveApplications = [
    {
      'leaveType': 'Vacation Leave',
      'dates': 'Mar 1 - Mar 5',
      'status': 'Approved'
    },
    {
      'leaveType': 'Sick Leave',
      'dates': 'Apr 10 - Apr 12',
      'status': 'Rejected'
    },
    {
      'leaveType': 'Emergency Leave',
      'dates': 'May 15 - May 16',
      'status': 'Approved'
    },
  ];

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
                  // Set color based on status
                  Color statusColor =
                      app['status'] == 'Approved' ? Colors.green : Colors.red;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(app['leaveType']!),
                      subtitle: Text('Dates: ${app['dates']}'),
                      trailing: Text(
                        app['status']!,
                        style: TextStyle(
                          color: statusColor, 
                          fontWeight: FontWeight.bold,
                        ),
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
