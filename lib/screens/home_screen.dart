import 'package:flutter/material.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'productos_screen.dart';
import 'carrito_screen.dart';
import 'perfil_cliente_screen.dart';
import 'sensores_screen.dart';

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
          nombreUsuario: _usuario?.displayName ?? 'Usuario FLORI',
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
          image: NetworkImage('https://images.unsplash.com/photo-1578985545062-69928b1d9587'),
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
                'Panadería y Pastelería',
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
          'FLORI',
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