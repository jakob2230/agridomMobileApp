import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class TimeInHandler {
  CameraController? cameraController;
  List<CameraDescription>? cameras;

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        cameraController =
            CameraController(cameras![0], ResolutionPreset.medium);
        await cameraController!.initialize();
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  // Capture an image and return its file path
  Future<String> captureTimeIn() async {
    String imagePath = "";
    if (cameraController == null ||
        !cameraController!.value.isInitialized) {
      debugPrint("Camera is not initialized!");
      return imagePath;
    }
    try {
      final XFile file = await cameraController!.takePicture();
      imagePath = file.path;
      debugPrint("Picture saved at: $imagePath");
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
    return imagePath;
  }

  void disposeCamera() {
    cameraController?.dispose();
  }
}
