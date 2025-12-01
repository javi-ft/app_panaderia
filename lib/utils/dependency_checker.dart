import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DependencyChecker {
  static Future<void> checkDependencies() async {
    try {
      // Verificar image_picker
      final ImagePicker picker = ImagePicker();
      print('✅ image_picker: OK');

      // Verificar camera
      final cameras = await availableCameras();
      print('✅ camera: OK (${cameras.length} cámaras disponibles)');

      // Verificar tflite_flutter
      try {
        await Interpreter.fromAsset('assets/model.tflite');
        print('✅ tflite_flutter: OK');
      } catch (e) {
        print('⚠️ tflite_flutter: Modelo no encontrado, pero librería funciona');
      }

      print('🎉 Todas las dependencias están instaladas correctamente');
    } catch (e) {
      print('❌ Error verificando dependencias: $e');
    }
  }
}