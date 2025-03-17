import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class TimeInHandler {
  CameraController? cameraController;
  List<CameraDescription>? cameras;

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      cameraController = CameraController(cameras![0], ResolutionPreset.medium);
      await cameraController!.initialize();
    }
  }

  Future<String> captureTimeIn() async {
    String imagePath = "";
    if (cameraController != null && cameraController!.value.isInitialized) {
      try {
        // 1. Take the picture
        final XFile file = await cameraController!.takePicture();

        // 2. Get the app's documents directory (works on Android/iOS, not web)
        final Directory appDocDir = await getApplicationDocumentsDirectory();

        // 3. Create "TimeInImages" subfolder if it doesn't exist
        final Directory imageDir = Directory(path.join(appDocDir.path, 'TimeInImages'));
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }

        // 4. Build a new file path
        final String newFileName = 'time_in_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String newPath = path.join(imageDir.path, newFileName);

        // 5. Copy the picture to the new folder
        await File(file.path).copy(newPath);

        // 6. Return the new path for the API
        imagePath = newPath;
      } catch (e) {
        print("Error taking picture: $e");
      }
    }
    return imagePath;
  }
  
  void disposeCamera() {
    cameraController?.dispose();
  }
}
