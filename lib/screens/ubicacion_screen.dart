import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UbicacionScreen extends StatefulWidget {
  const UbicacionScreen({super.key});

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  Map<String, dynamic>? _infoTienda;

  @override
  void initState() {
    super.initState();
    _cargarInfoTienda();
  }

  Future<void> _cargarInfoTienda() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tienda')
          .doc('principal')
          .get();

      if (snapshot.exists) {
        setState(() {
          _infoTienda = snapshot.data();
        });
      }
    } catch (e) {
      print('Error cargando info tienda: $e');
    }
  }

  void _abrirGoogleMaps() async {
    const url = 'https://maps.google.com/?q=Panaderia+FLORI+Huancayo+Peru';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _mostrarMensaje('No se pudo abrir Google Maps');
    }
  }

  void _abrirWaze() async {
    const url = 'https://waze.com/ul?q=Panaderia+FLORI+Huancayo+Peru&navigate=yes';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _mostrarMensaje('No se pudo abrir Waze');
    }
  }

  void _llamarTienda() async {
    final url = Uri.parse('tel:+51944975522');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _mostrarMensaje('No se pudo realizar la llamada');
    }
  }

  void _enviarWhatsApp() async {
    final message = 'Hola, quiero información de sus productos de panadería FLORI';
    final url = Uri.parse('https://wa.me/51944975522?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _mostrarMensaje('No se pudo abrir WhatsApp');
    }
  }

  void _mostrarOpcionesNavegacion() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cómo quieres llegar?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.red),
              title: const Text('Google Maps'),
              subtitle: const Text('Navegación paso a paso'),
              onTap: () {
                Navigator.pop(context);
                _abrirGoogleMaps();
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation, color: Colors.blue),
              title: const Text('Waze'),
              subtitle: const Text('Rutas en tiempo real'),
              onTap: () {
                Navigator.pop(context);
                _abrirWaze();
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuestra Ubicación'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown.shade600, Colors.orange.shade400],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Icon(Icons.storefront, size: 50, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    'Panadería FLORI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _infoTienda?['direccion'] ?? 'Av. Leoncio Prado Gutierrez #103, Huancayo',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Información de contacto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de Contacto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(Icons.phone, 'Teléfono', '+51 944 975 522'),
                    _buildInfoItem(Icons.email, 'Email', 'pan_pas_flori@gmail.com'),
                    _buildInfoItem(Icons.access_time, 'Horario', 'Lunes a Domingo: 6:00 AM - 10:00 PM'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botones de acción
            const Text(
              'Cómo llegar:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _mostrarOpcionesNavegacion,
                    icon: const Icon(Icons.map),
                    label: const Text('Ver en Mapas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _llamarTienda,
                    icon: const Icon(Icons.phone),
                    label: const Text('Llamar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _enviarWhatsApp,
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Servicios
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nuestros Servicios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildServiceChip('🚚 Delivery Gratis'),
                    _buildServiceChip('🎂 Pedidos Especiales'),
                    _buildServiceChip('💳 Tarjetas Crédito/Débito'),
                    _buildServiceChip('📦 Catering para Eventos'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.brown),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.brown.shade200),
      ),
      child: Text(text),
    );
  }
}