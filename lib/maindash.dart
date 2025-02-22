import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';

import 'package:mobileapp/file_leave_screen.dart';
import 'package:mobileapp/time_in_handler.dart';

class MainDash extends StatefulWidget {
  const MainDash({super.key});

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
  }

  Future<void> initializeCamera() async {
    await timeInHandler.initializeCamera();
    if (mounted) {
      setState(() {});
    }
  }

  void updateTime() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() {
          currentTime = DateFormat('hh : mm : ss a').format(DateTime.now());
          currentDate = DateFormat('MMMM dd, yyyy EEEE').format(DateTime.now());
        });
      }
    });
  }

  Future<void> handleTimeIn() async {
    Map<String, String> entry = await timeInHandler.captureTimeIn();
    setState(() {
      attendanceList.add({
        "name": "Employee ${attendanceList.length + 1}",
        "time_in": entry["time"]!,
        "time_out": "Not Yet Out",
        "image": entry["image"]!
      });
    });
  }

  void handleTimeOut() {
    if (attendanceList.isNotEmpty) {
      setState(() {
        int index = attendanceList.length - 1;
        attendanceList[index]["time_out"] = DateFormat('hh:mm:ss a').format(DateTime.now());
      });
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
      drawer: Drawer(
        child: Container(
          color: Color(0xFFF44336),
          child: Column(
            children: [
              DrawerHeader(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(color: Color(0xFFF44336)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFFF44336), size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Text('Username', style: TextStyle(color: Colors.white, fontSize: 20)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.white),
                title: const Text('Leave approval', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
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
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Camera preview / last captured image
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF44336), width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                height: 200,
                width: 300,
                child: attendanceList.isNotEmpty && attendanceList.last['image']!.isNotEmpty
                    ? Image.file(File(attendanceList.last['image']!),
                    fit: BoxFit.cover,) 
                    : Container(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            // Current time and date
            Text(currentTime, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text(currentDate, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            // Combined buttons: Time In, Time Out, File Leave
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: handleTimeIn,
                  child: const Text('Time In', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: handleTimeOut,
                  child: const Text('Time Out', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FileLeaveScreen()),
                    );
                  },
                  child: const Text('File Leave', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Attendance List header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: const Center(
                child: Text(
                  'Attendance List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            // Attendance List table without the "Actions" column
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Time IN', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Time OUT', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(attendanceList.length, (index) => DataRow(cells: [
                        DataCell(Text(attendanceList[index]['name']!)),
                        DataCell(Text(attendanceList[index]['time_in']!)),
                        DataCell(Text(attendanceList[index]['time_out']!)),
                      ]
                      )
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
    super.dispose();
  }
}
