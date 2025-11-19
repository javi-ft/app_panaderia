import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaScreen extends StatelessWidget {
  const MapaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Coordenadas de Pastelería Flori (Huancayo)
    final LatLng ubicacionFlori = LatLng(-12.0728896, -75.1900345);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ubicación - Pastelería Flori',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown,
        centerTitle: true,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: ubicacionFlori,
          initialZoom: 17.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          // 🌍 Capa de mapa base (OpenStreetMap)
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.app_panaderia',
          ),

          // 📍 Marcador de la pastelería
          MarkerLayer(
            markers: [
              Marker(
                point: ubicacionFlori,
                width: 80,
                height: 80,
                child: Column(
                  children: const [
                    Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                    Text(
                      'Pastelería Flori',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // 🔙 Botón flotante para volver atrás
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown,
        child: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
