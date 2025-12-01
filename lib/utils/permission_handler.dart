import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  // Solicitar permisos de cámara
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Solicitar permisos de almacenamiento
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Verificar si los permisos están concedidos
  static Future<bool> get arePermissionsGranted async {
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;
    
    return cameraStatus.isGranted && storageStatus.isGranted;
  }

  // Abrir configuración de la app
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}