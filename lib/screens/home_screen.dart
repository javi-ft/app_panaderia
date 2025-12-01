import 'package:flutter/material.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'productos_screen.dart';
import 'carrito_screen.dart';
import 'perfil_cliente_screen.dart';
import 'sensores_screen.dart';
import '../services/recomendacion_service.dart';
import 'recomendaciones_screen.dart';
import '../models/producto_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _carrito = [];
  final List<Map<String, dynamic>> _favoritos = [];
  final User? _usuario = FirebaseAuth.instance.currentUser;

// LUEGO MODIFICA EL MÉTODO _mostrarDetallesConRecomendaciones:

void _mostrarDetallesConRecomendaciones(Map<String, dynamic> productoData) {
  final recomendacionService = RecomendacionService();
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => FutureBuilder<List<Producto>>(
      future: recomendacionService.obtenerRecomendacionesPorNombre(
        productoData['nombre'], 4), // Aumenté a 4 recomendaciones
      builder: (context, snapshot) {
        final recomendados = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: controller,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                
                // Detalles del producto actual
                Text(
                  productoData['nombre'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Precio: S/ ${productoData['precio']}'),
                if (productoData['descripcion'] != null && 
                    productoData['descripcion'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    productoData['descripcion'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _agregarAlCarrito(productoData);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ ${productoData['nombre']} agregado al carrito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Agregar al carrito'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const Divider(height: 32),
                
                // Sección de recomendaciones
                const Text(
                  'Productos que podrían gustarte:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                if (isLoading) 
                  const Center(child: CircularProgressIndicator()),
                
                if (!isLoading && recomendados.isEmpty)
                  _buildSinRecomendaciones(),
                
                if (!isLoading && recomendados.isNotEmpty)
                  ...recomendados.map((prod) => ListTile(
                    leading: prod.imagen.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              prod.imagen, 
                              width: 50, 
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.shopping_bag),
                            ),
                          )
                        : const Icon(Icons.shopping_bag),
                    title: Text(prod.nombre),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('S/ ${prod.precio.toStringAsFixed(2)}'),
                        if (prod.categoria.isNotEmpty)
                          Text(
                            prod.categoria,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                      onPressed: () => _agregarAlCarrito(prod.toMap()),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _mostrarDetallesConRecomendaciones(prod.toMap());
                    },
                  )),
                  
                const SizedBox(height: 16),
                
                if (recomendados.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecomendacionesScreen(
                              productoReferencia: productoData['nombre'],
                            ),
                          ),
                        );
                      },
                      child: const Text('Ver más recomendaciones'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// WIDGET PARA CUANDO NO HAY RECOMENDACIONES
Widget _buildSinRecomendaciones() {
  return Container(
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      children: [
        const Icon(Icons.search_off, size: 40, color: Colors.grey),
        const SizedBox(height: 8),
        const Text(
          'No hay recomendaciones disponibles',
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Prueba otros productos similares',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

  // ===============================
  //       CARRITO FUNCTIONS
  // ===============================

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    final index = _carrito.indexWhere((p) => p['id'] == producto['id']);

    if (index >= 0) {
      setState(() {
        _carrito[index]['cantidad'] = (_carrito[index]['cantidad'] ?? 1) + 1;
      });
    } else {
      setState(() {
        _carrito.add({...producto, 'cantidad': 1});
      });
    }
  }

  void _eliminarDelCarrito(int index) {
    setState(() {
      _carrito.removeAt(index);
    });
  }

  void _vaciarCarrito() {
    setState(() {
      _carrito.clear();
    });
  }

  void _aumentarCantidad(int index) {
    setState(() {
      _carrito[index]['cantidad'] = (_carrito[index]['cantidad'] ?? 1) + 1;
    });
  }

  void _disminuirCantidad(int index) {
    setState(() {
      final cantidad = _carrito[index]['cantidad'] ?? 1;
      if (cantidad > 1) {
        _carrito[index]['cantidad'] = cantidad - 1;
      } else {
        _carrito.removeAt(index);
      }
    });
  }
  void _navegarASensores() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SensoresScreen()),
    );
  }
  // ===============================
  //       FAVORITOS FUNCTIONS
  // ===============================

  void _agregarAFavoritos(Map<String, dynamic> producto) {
    final index = _favoritos.indexWhere((p) => p['id'] == producto['id']);

    if (index >= 0) {
      // Si ya está en favoritos, lo quitamos
      setState(() {
        _favoritos.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${producto['nombre']} removido de favoritos'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.grey,
        ),
      );
    } else {
      // Si no está, lo agregamos
      setState(() {
        _favoritos.add({...producto});
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❤️ ${producto['nombre']} agregado a favoritos'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.pink,
        ),
      );
    }
  }

  bool _esFavorito(String productoId) {
    return _favoritos.any((p) => p['id'] == productoId);
  }

  // ===============================
  //       WIDGET PRODUCTOS
  // ===============================

  Widget _buildPantallaProductos() {
    return Column(
      children: [
        _buildBannerPasteleria(),
        Expanded(
          child: ProductosScreen(
            carrito: _carrito,
            onAgregarAlCarrito: _agregarAlCarrito,
            onEliminarDelCarrito: _eliminarDelCarrito,
            onVaciarCarrito: _vaciarCarrito,
            onAumentarCantidad: _aumentarCantidad,
            onDisminuirCantidad: _disminuirCantidad,
            calcularTotal: _calcularTotal,
            onAgregarAFavoritos: _agregarAFavoritos,
            esFavorito: _esFavorito,
            onMostrarDetalles: _mostrarDetallesConRecomendaciones,
          ),
        ),
      ],
    );
  }

  double _calcularTotal() {
    double total = 0;
    for (var item in _carrito) {
      final precio = double.tryParse(item['precio'].toString()) ?? 0;
      final cantidad = item['cantidad'] ?? 1;
      total += precio * cantidad;
    }
    return total;
  }

  int _calcularTotalProductos() {
    int total = 0;
    for (var item in _carrito) {
      final cantidad = item['cantidad'] ?? 1;
      total += (cantidad is num) ? cantidad.toInt() : int.tryParse(cantidad.toString()) ?? 1;
    }
    return total;
  }

  // ===============================
  //  NAVEGAR A PANTALLAS
  // ===============================

  void _navegarAlPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerfilClienteScreen(
          favoritos: _favoritos,
          nombreUsuario: _usuario?.displayName ?? 'Usuario MINIMARKET',
          emailUsuario: _usuario?.email ?? 'No especificado',
        ),
      ),
    );
  }

  void _navegarAlCarrito() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarritoScreen(
          carrito: _carrito,
          onVaciarCarrito: _vaciarCarrito,
          onEliminarDelCarrito: _eliminarDelCarrito,
          onAumentarCantidad: _aumentarCantidad,
          onDisminuirCantidad: _disminuirCantidad,
        ),
      ),
    );
  }

  // ===============================
  //       WIDGETS PERSONALIZADOS
  // ===============================

  Widget _buildBannerPasteleria() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage('https://invyctaretail.com/wp-content/uploads/2023/04/modulo-check-out-L.webp'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withOpacity(0.3),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Text(
                'productos frescos y cercanía',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.8),
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'El aroma que enamora… el sabor que conquista.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.8),
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  //       BUILD
  // ===============================

  @override
  Widget build(BuildContext context) {
    final totalProductos = _calcularTotalProductos();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MINIMARKET',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _navegarAlCarrito,
              ),
              if (_carrito.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      totalProductos.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      // KEY FIX: Usar una Key única para evitar que ProductosScreen se reconstruya completamente
      body: KeyedSubtree(
        key: const ValueKey('productos_screen'),
        child: _buildPantallaProductos(),
      ),

      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.brown.shade50,
          border: Border(
            top: BorderSide(
              color: Colors.brown.shade300,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bakery_dining,
                    size: 30,
                    color: Colors.brown.shade800,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Productos',
                    style: TextStyle(
                      color: Colors.brown.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.brown.shade300,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.person, size: 30),
                    onPressed: _navegarAlPerfil,
                    color: Colors.brown.shade700,
                  ),
                  Text(
                    'Perfil',
                    style: TextStyle(
                      color: Colors.brown.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}