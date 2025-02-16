import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:mobileapp/file_leave_screen.dart';

class MainDash extends StatefulWidget {
  const MainDash({super.key});

  @override
  State<MainDash> createState() => _MainDashState();
}

class _MainDashState extends State<MainDash> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
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
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _cameraController = CameraController(cameras![0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('images/SFgroup.png', height: 80),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _cameraController == null || !_cameraController!.value.isInitialized
                  ? Container(height: 200, width: 300, color: Colors.grey)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(height: 200, width: 300, child: CameraPreview(_cameraController!)),
                    ),
            ),
            SizedBox(height: 20),
            Text(currentTime, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text(currentDate, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: Text('Time In', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: Text('Time Out', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FileLeaveScreen()),
                );
              },
              child: Text('File Leave', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: Center(
                child: Text(
                  'Attendance List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      columns: [
                        DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Time IN', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Time OUT', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: List.generate(50, (index) => DataRow(cells: [
                        DataCell(Text("Employee \${index + 1}")),
                        DataCell(Text("7:00 AM")),
                        DataCell(Text("4:00 PM")),
                      ])),
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
    _cameraController?.dispose();
    timer?.cancel();
    super.dispose();
  }
}