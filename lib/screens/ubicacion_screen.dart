import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class UbicacionScreen extends StatefulWidget {
  const UbicacionScreen({super.key});

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _infoTienda;
  bool _cargandoUbicacion = false;
  double _distanciaCalculada = 0.0;
  LatLng? _ubicacionTienda;
  LatLng? _ubicacionUsuario;
  LatLng? _ubicacionEntrega;
  List<LatLng> _rutaPoints = [];
  bool _ubicacionSeleccionada = false;

  // Controladores de texto
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarInfoTienda();
  }

  Future<void> _cargarInfoTienda() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('tienda').doc('principal').get();

      if (snapshot.exists) {
        setState(() {
          _infoTienda = snapshot.data();
          final geoPoint = _infoTienda?['ubicacion'] as GeoPoint?;
          if (geoPoint != null) {
            _ubicacionTienda = LatLng(geoPoint.latitude, geoPoint.longitude);
          } else {
            _ubicacionTienda = LatLng(-12.0697, -75.2056); // Huancayo por defecto
          }
        });
        _mapController.move(_ubicacionTienda!, 15.0);
      }
    } catch (e) {
      print('Error cargando info tienda: $e');
    }
  }

  Future<void> _obtenerUbicacionActual() async {
    setState(() => _cargandoUbicacion = true);

    try {
      bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        _mostrarMensaje('Activa la ubicación en tu dispositivo');
        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          _mostrarMensaje('Se necesitan permisos de ubicación');
          return;
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        _mostrarMensaje('Permisos de ubicación denegados permanentemente');
        return;
      }

      Position posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _ubicacionUsuario = LatLng(posicion.latitude, posicion.longitude);
        _ubicacionEntrega = _ubicacionUsuario;
        _cargandoUbicacion = false;
      });

      _obtenerRuta();
      _mapController.move(_ubicacionUsuario!, 15.0);
    } catch (e) {
      setState(() => _cargandoUbicacion = false);
      _mostrarMensaje('Error obteniendo ubicación: $e');
    }
  }

  // 🗺️ Obtener ruta real con OSRM (gratis)
  Future<void> _obtenerRuta() async {
    if (_ubicacionTienda == null || _ubicacionEntrega == null) return;

    final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${_ubicacionTienda!.longitude},${_ubicacionTienda!.latitude};${_ubicacionEntrega!.longitude},${_ubicacionEntrega!.latitude}?overview=full&geometries=geojson');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
        final distanciaMetros = data['routes'][0]['distance'];

        setState(() {
          _rutaPoints = coordinates
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
          _distanciaCalculada = distanciaMetros / 1000; // km
        });
      } else {
        _mostrarMensaje('Error al obtener la ruta (${response.statusCode})');
      }
    } catch (e) {
      _mostrarMensaje('Error al calcular ruta: $e');
    }
  }

  void _seleccionarUbicacionEnMapa(LatLng latlng) {
    setState(() {
      _ubicacionEntrega = latlng;
      _ubicacionSeleccionada = true;
    });
    _obtenerRuta();
  }

  void _buscarDireccion() async {
    if (_busquedaController.text.isEmpty) return;

    final query = Uri.encodeComponent(_busquedaController.text);
    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=1';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'app_panaderia_flutter/1.0'
      });
      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          setState(() {
            _ubicacionEntrega = LatLng(lat, lon);
            _ubicacionSeleccionada = true;
          });
          _obtenerRuta();
          _mapController.move(_ubicacionEntrega!, 15.0);
        } else {
          _mostrarMensaje('No se encontró la dirección');
        }
      }
    } catch (e) {
      _mostrarMensaje('Error buscando dirección: $e');
    }
  }

  void _mostrarResumenDelivery() {
    if (_ubicacionTienda == null || _ubicacionEntrega == null) return;

    final double tiempoEstimado = _distanciaCalculada * 2.5;
    final double costoDelivery = _distanciaCalculada > 5 ? 8.0 : 5.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚚 Resumen de Delivery'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoDeliveryItem('📏 Distancia:',
                  '${_distanciaCalculada.toStringAsFixed(1)} km'),
              _buildInfoDeliveryItem(
                  '⏱️ Tiempo estimado:', '${tiempoEstimado.toStringAsFixed(0)} min'),
              _buildInfoDeliveryItem(
                  '💰 Costo delivery:', 'S/ ${costoDelivery.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              TextField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección exacta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _referenciaController,
                decoration: const InputDecoration(
                  labelText: 'Referencia',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              if (_direccionController.text.isEmpty) {
                _mostrarMensaje('Por favor ingresa tu dirección');
                return;
              }
              Navigator.pop(context);
              _solicitarDelivery(costoDelivery);
            },
            child: const Text('Confirmar Delivery',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDeliveryItem(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child:
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(valor)),
        ],
      ),
    );
  }

  void _solicitarDelivery(double costo) async {
    await _guardarPedidoEnFirestore(costo);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Pedido confirmado'),
        content: Text(
            'Tu pedido ha sido registrado correctamente.\nCosto: S/ ${costo.toStringAsFixed(2)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarPedidoEnFirestore(double costoDelivery) async {
    try {
      String userUid = await _obtenerUidUsuarioActual();

      final pedidoRef = FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(userUid)
          .collection('Pedidos')
          .doc();

      await pedidoRef.set({
        'id': pedidoRef.id,
        'fecha': Timestamp.now(),
        'total': costoDelivery,
        'estado': 'Pendiente',
        'tipo': 'Delivery',
        'distancia': _distanciaCalculada,
        'direccion': _direccionController.text,
        'referencia': _referenciaController.text,
        'ubicacionEntrega': GeoPoint(
            _ubicacionEntrega!.latitude, _ubicacionEntrega!.longitude),
      });

      print('Pedido guardado con ID: ${pedidoRef.id}');
    } catch (e) {
      _mostrarMensaje('Error al guardar el pedido: $e');
    }
  }

  Future<String> _obtenerUidUsuarioActual() async {
    return 'usuario_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _referenciaController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu ubicación'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _obtenerUbicacionActual,
          ),
        ],
      ),
      body: _ubicacionTienda == null
          ? const Center(child: CircularProgressIndicator())
          : _buildMapaInteractivo(),
    );
  }

  Widget _buildMapaInteractivo() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _ubicacionTienda!,
            initialZoom: 15.0,
            onTap: (_, point) => _seleccionarUbicacionEnMapa(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app_panaderia',
            ),
            if (_rutaPoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(points: _rutaPoints, strokeWidth: 4, color: Colors.blue),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _ubicacionTienda!,
                  width: 80,
                  height: 80,
                  child: const Column(
                    children: [
                      Icon(Icons.store, color: Colors.red, size: 40),
                      Text('TIENDA',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (_ubicacionEntrega != null)
                  Marker(
                    point: _ubicacionEntrega!,
                    width: 80,
                    height: 80,
                    child: const Column(
                      children: [
                        Icon(Icons.location_on, color: Colors.green, size: 40),
                        Text('ENTREGA',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        // 🔍 Barra de búsqueda
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Card(
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _busquedaController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar dirección...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _buscarDireccion(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _buscarDireccion,
                  ),
                ],
              ),
            ),
          ),
        ),
        // 📍 Panel inferior
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            children: [
              if (_ubicacionSeleccionada)
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('📍 Ubicación Seleccionada',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Distancia: ${_distanciaCalculada.toStringAsFixed(1)} km'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delivery_dining),
                          label: const Text('Confirmar Esta Ubicación'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: _mostrarResumenDelivery,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
