import 'package:flutter/material.dart';
import 'productos_screen.dart';
import 'historial_pedidos_screen.dart';
import 'ubicacion_screen.dart';
import 'carrito_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _carrito = [];

  // Funciones para manejar el carrito
  void _agregarAlCarrito(Map<String, dynamic> producto) {
    final productoExistente = _carrito.indexWhere((p) => p['id'] == producto['id']);
    
    if (productoExistente >= 0) {
      setState(() {
        _carrito[productoExistente]['cantidad'] = 
            (_carrito[productoExistente]['cantidad'] ?? 1) + 1;
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
      total += cantidad is int ? cantidad : int.tryParse(cantidad.toString()) ?? 1;
    }
    return total;
  }

  // Pantallas del bottom navigation
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      ProductosScreen(
        carrito: _carrito,
        onAgregarAlCarrito: _agregarAlCarrito,
        onEliminarDelCarrito: _eliminarDelCarrito,
        onVaciarCarrito: _vaciarCarrito,
        onAumentarCantidad: _aumentarCantidad,
        onDisminuirCantidad: _disminuirCantidad,
        calcularTotal: _calcularTotal,
      ),
      const UbicacionScreen(),
      HistorialPedidosScreen(carrito: _carrito),
    ]);
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

  @override
  Widget build(BuildContext context) {
    final totalProductos = _calcularTotalProductos();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FLORI - Panadería y Pastelería'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Contador del carrito en el AppBar (arriba a la derecha)
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bakery_dining),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Ubicación',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
        backgroundColor: Colors.brown.shade50,
        selectedItemColor: Colors.brown.shade700,
        unselectedItemColor: Colors.brown.shade400,
      ),
    );
  }
}