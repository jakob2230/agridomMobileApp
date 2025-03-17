import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class FileLeaveScreen extends StatefulWidget {
  final String employeeId;
  const FileLeaveScreen({super.key, required this.employeeId});

  @override
  _FileLeaveScreenState createState() => _FileLeaveScreenState();
}

class _FileLeaveScreenState extends State<FileLeaveScreen> {
  int remainingLeave = 15; // Regular leave credits
  int totalLeaveCredits = 16;
  
  int remainingSickLeave = 10; // Sick leave credits
  int totalSickLeave = 10;
  
  String? selectedLeaveType;
  DateTime? startDate;
  DateTime? endDate;
  int leaveDays = 0;

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // Function to select a date
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          _startDateController.text = DateFormat.yMMMd().format(picked);
          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = null;
            _endDateController.text = "";
          }
        } else {
          if (startDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a start date first!')),
            );
            return;
          }
          if (picked.isBefore(startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('End date cannot be before start date!')),
            );
            return;
          }
          endDate = picked;
          _endDateController.text = DateFormat.yMMMd().format(picked);
        }
        // Calculate leave duration
        if (startDate != null && endDate != null) {
          leaveDays = endDate!.difference(startDate!).inDays + 1;
        }
      });
    }
  }

  // Function to submit leave to the backend
  Future<void> submitLeave() async {
    // Prepare leave request payload
    final Map<String, dynamic> payload = {
      "employee_id": widget.employeeId,
      "leaveType": selectedLeaveType,
      "startDate": DateFormat('yyyy-MM-dd').format(startDate!), // Only date
      "endDate": DateFormat('yyyy-MM-dd').format(endDate!),     // Only date
      "leaveDays": leaveDays,
      "reason": _reasonController.text,
    };

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/api/submit-leave/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"])),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"])),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Leave'),
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Centered Logo & Leave Balance Information
            Center(
              child: Column(
                children: [
                  Image.asset('images/SFgroup.png', height: 75),
                  const SizedBox(height: 10),
                  Text(
                    "Leave Credit score: $remainingLeave/$totalLeaveCredits",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Sick Leave Credit: $remainingSickLeave/$totalSickLeave",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Leave Type Dropdown
            const Text("Select Leave Type:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              value: selectedLeaveType,
              items: ["Sick Leave", "Vacation Leave", "Emergency Leave"]
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedLeaveType = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Choose Leave Type",
              ),
            ),
            const SizedBox(height: 15),
            // Leave Start Date
            const Text("Leave Start Date:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              readOnly: true,
              controller: _startDateController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Select Start Date",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, true),
                ),
              ),
            ),
            const SizedBox(height: 15),
            // Leave End Date
            const Text("Leave End Date:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              readOnly: true,
              controller: _endDateController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Select End Date",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, false),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Display Number of Leave Days
            if (leaveDays > 0)
              Center(
                child: Text(
                  "Total Leave Days: $leaveDays",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            const SizedBox(height: 5),
            // Reason Text Field
            const Text("Reason:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your reason for leave",
              ),
            ),
            const SizedBox(height: 15),
            // Submit Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                ),
                onPressed: () {
                  if (selectedLeaveType != null && startDate != null && endDate != null) {
                    // If Sick Leave is selected, ensure there is sufficient sick leave credit
                    if (selectedLeaveType == "Sick Leave") {
                      if (remainingSickLeave >= leaveDays) {
                        setState(() {
                          remainingSickLeave -= leaveDays;
                        });
                        submitLeave();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Insufficient sick leave balance!')),
                        );
                      }
                    } else {
                      // For other leave types, ensure there is sufficient regular leave credit
                      if (remainingLeave >= leaveDays) {
                        setState(() {
                          remainingLeave -= leaveDays;
                        });
                        submitLeave();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Insufficient leave balance!')),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please complete the form!')),
                    );
                  }
                },
                child: const Text("Submit Leave", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
