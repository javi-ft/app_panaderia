import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensoresScreen extends StatefulWidget {
  const SensoresScreen({super.key});

  @override
  State<SensoresScreen> createState() => _SensoresScreenState();
}

class _SensoresScreenState extends State<SensoresScreen> {
  String acelerometro = '';
  String giroscopio = '';
  String magnetometro = '';
  String userAccel = '';

  @override
  void initState() {
    super.initState();
    _iniciarSensores();
  }

  void _iniciarSensores() {
    // Acelerómetro
    accelerometerEventStream().listen((e) {
      if (mounted) {
        setState(() {
          acelerometro = 'Acelerómetro:\nX: ${e.x.toStringAsFixed(2)}\nY: ${e.y.toStringAsFixed(2)}\nZ: ${e.z.toStringAsFixed(2)}';
        });
      }
    });

    // Giroscopio
    gyroscopeEventStream().listen((e) {
      if (mounted) {
        setState(() {
          giroscopio = 'Giroscopio:\nX: ${e.x.toStringAsFixed(2)}\nY: ${e.y.toStringAsFixed(2)}\nZ: ${e.z.toStringAsFixed(2)}';
        });
      }
    });

    // Magnetómetro
    magnetometerEventStream().listen((e) {
      if (mounted) {
        setState(() {
          magnetometro = 'Magnetómetro:\nX: ${e.x.toStringAsFixed(2)}\nY: ${e.y.toStringAsFixed(2)}\nZ: ${e.z.toStringAsFixed(2)}';
        });
      }
    });

    // Acelerómetro del usuario
    userAccelerometerEventStream().listen((e) {
      if (mounted) {
        setState(() {
          userAccel = 'Aceleración Usuario:\nX: ${e.x.toStringAsFixed(2)}\nY: ${e.y.toStringAsFixed(2)}\nZ: ${e.z.toStringAsFixed(2)}';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensores del Móvil'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTarjetaSensor(acelerometro, '📱 Acelerómetro', Colors.blue),
            const SizedBox(height: 16),
            _buildTarjetaSensor(giroscopio, '🔄 Giroscopio', Colors.green),
            const SizedBox(height: 16),
            _buildTarjetaSensor(magnetometro, '🧲 Magnetómetro', Colors.orange),
            const SizedBox(height: 16),
            _buildTarjetaSensor(userAccel, '👤 Aceleración Usuario', Colors.purple),
            const SizedBox(height: 20),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaSensor(String datos, String titulo, Color color) {
    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              datos.isEmpty ? 'Esperando datos...' : datos,
              style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Card(
      color: Colors.brown.shade50, // ✅ Ya no sale subrayado en rojo
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ℹ️ Información de Sensores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Acelerómetro: Movimiento y orientación del dispositivo\n'
              '• Giroscopio: Rotación y velocidad angular\n'
              '• Magnetómetro: Campo magnético (brújula)\n'
              '• Aceleración Usuario: Movimiento sin gravedad',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Los streams se cierran automáticamente
    super.dispose();
  }
}