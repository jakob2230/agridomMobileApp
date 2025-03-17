import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'file_leave_screen.dart';
import 'time_in_handler.dart';
import 'drawer_widget.dart';

class MainDash extends StatefulWidget {
  final String fullName;
  final String employeeId; // Add this line

  const MainDash({
    super.key, 
    required this.fullName,
    required this.employeeId, // Add this line
  });

  @override
  State<MainDash> createState() => _MainDashState();
}

class _MainDashState extends State<MainDash> {
  TimeInHandler timeInHandler = TimeInHandler();
  List<Map<String, String>> attendanceList = [];
  String currentTime = "";
  String currentDate = "";
  Timer? timer;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    updateTime();
    fetchAttendanceList(); // Fetch attendance on initialization
  }

  Future<void> initializeCamera() async {
    try {
      await timeInHandler.initializeCamera();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error initializing camera: $e")),
        );
      }
    }
  }

  void updateTime() {
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() {
          currentTime = DateFormat('hh : mm : ss a').format(DateTime.now());
          currentDate = DateFormat('MMMM dd, yyyy EEEE').format(DateTime.now());
        });
      }
    });
  }

  Future<void> fetchAttendanceList() async {
    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/api/attendance/"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"]) {
          setState(() {
            // Convert the dynamic Map to Map<String, String>
            attendanceList = (data["attendance"] as List).map((item) => {
              "name": item["name"]?.toString() ?? "",
              "time_in": item["time_in"]?.toString() ?? "",
              "time_out": item["time_out"]?.toString() ?? "Not Yet Out",
              "location": item["location"]?.toString() ?? "",
            }).toList();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error fetching attendance list: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      print("Error fetching attendance: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> handleTimeIn() async {
    try {
      // Check if user already has an entry for today
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      bool hasEntryToday = attendanceList.any((entry) {
        String entryTimeIn = entry["time_in"] ?? "";
        return entry["name"] == widget.fullName &&
               entryTimeIn.isNotEmpty &&
               entryTimeIn.contains(today);
      });

      if (hasEntryToday) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have already timed in for today")),
        );
        return;
      }

      // Get the current location first
      String currentLocation = await getCurrentLocation();
      
      // Capture image
      String? capturedImagePath;
      try {
        capturedImagePath = await timeInHandler.captureTimeIn();
      } catch (e) {
        print("Error capturing image: $e");
        // Continue without image if there's an error
      }

      // Prepare request body
      final requestBody = {
        "employee_id": widget.employeeId,
        "location": currentLocation,
      };

      // Only add image if it was successfully captured
      if (capturedImagePath != null) {
        requestBody["image"] = capturedImagePath;
      }

      // Send POST request
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/api/time-in/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      // Debug prints
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"]) {
          await Future.delayed(const Duration(milliseconds: 500));
          await fetchAttendanceList();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Time in recorded successfully")),
          );
        } else {
          throw Exception(data["message"] ?? "Failed to record time in");
        }
      } else {
        throw Exception("Server returned status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Time in error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error recording time in: $e")),
      );
    }
  }

  Future<String> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return "Location services disabled";
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return "Location permissions denied";
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return "Location permissions permanently denied";
    }

    Position position = await Geolocator.getCurrentPosition();
    // Return a formatted string of latitude and longitude
    return "${position.latitude}, ${position.longitude}";
  }

  Future<void> handleTimeOut() async {
    try {
      // Check if user already has an active time entry for today
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      bool hasActiveEntry = attendanceList.any((entry) {
        String entryTimeIn = entry["time_in"] ?? "";
        return entry["name"] == widget.fullName &&
               entry["time_out"] == "Not Yet Out" &&
               entryTimeIn.contains(today);
      });

      if (!hasActiveEntry) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No active time entry found for today")),
        );
        return;
      }

      // Send time-out request
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/api/time-out/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "employee_id": widget.employeeId,
        }),
      );

      print("Time out response: ${response.body}"); // Debug print

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"]) {
          // Refresh the attendance list
          await Future.delayed(const Duration(milliseconds: 500));
          await fetchAttendanceList();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Time out recorded successfully")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Failed to record time out")),
          );
        }
      } else {
        print("Error status code: ${response.statusCode}");
        print("Error response: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error recording time out: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Time out exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        centerTitle: true,
        title: Image.asset(
          'images/SFgroup.png',
          height: 60,
          fit: BoxFit.contain,
        ),
      ),
      // Pass the user's full name to the AppDrawer here:
      drawer: AppDrawer(fullName: widget.fullName),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Live Camera Preview
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF44336), width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                height: 200,
                width: 300,
                child: (timeInHandler.cameraController != null &&
                        timeInHandler.cameraController!.value.isInitialized)
                    ? CameraPreview(timeInHandler.cameraController!)
                    : Container(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            // Current Time & Date
            Text(
              currentTime,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              currentDate,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            // Action Buttons: Time In, Time Out, File Leave
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: handleTimeIn,
                  child: const Text('Time In', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: handleTimeOut,
                  child: const Text('Time Out', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FileLeaveScreen(employeeId: widget.employeeId)),
                    );
                  },
                  child: const Text('File Leave', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Attendance List Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: const Center(
                child: Text(
                  'Attendance List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            // Attendance List Table wrapped in scroll views
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(
                        label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      DataColumn(
                        label: Text('Time In', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      DataColumn(
                        label: Text('Time Out', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      DataColumn(
                        label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                    rows: List.generate(
                      attendanceList.length,
                      (index) => DataRow(
                        cells: [
                          DataCell(Text(attendanceList[index]['name']!)),
                          DataCell(Text(attendanceList[index]['time_in']!)),
                          DataCell(Text(attendanceList[index]['time_out']!)),
                          DataCell(Text(attendanceList[index]['location']!)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    timeInHandler.disposeCamera();
    super.dispose();
  }
}

// In your login_view.dart or wherever you handle login success
void navigateToMainDash(BuildContext context, Map<String, dynamic> data) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MainDash(
        fullName: "${data["first_name"]} ${data["surname"]}",
        employeeId: data["username"], // or however you receive the employee ID
      ),
    ),
  );
}
