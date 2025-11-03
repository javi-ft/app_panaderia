import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarritoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final VoidCallback onVaciarCarrito;
  final void Function(int) onEliminarDelCarrito;
  final void Function(int) onAumentarCantidad;
  final void Function(int) onDisminuirCantidad;

  const CarritoScreen({
    super.key,
    required this.carrito,
    required this.onVaciarCarrito,
    required this.onEliminarDelCarrito,
    required this.onAumentarCantidad,
    required this.onDisminuirCantidad,
  });

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  bool _isLoading = false;

  double _calcularTotal() {
    double total = 0;
    for (var item in widget.carrito) {
      final precio = double.tryParse(item['precio'].toString()) ?? 0;
      final cantidad = item['cantidad'] ?? 1;
      total += precio * cantidad;
    }
    return total;
  }

  int _calcularTotalProductos() {
    int total = 0;
    for (var item in widget.carrito) {
      final cantidad = item['cantidad'] ?? 1;
      total += cantidad is int ? cantidad : int.tryParse(cantidad.toString()) ?? 1;
    }
    return total;
  }

  Future<void> _realizarPedido() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para realizar un pedido')),
      );
      return;
    }

    if (widget.carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pedidoRef = FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(user.uid)
          .collection('Pedidos')
          .doc();

      final pedido = {
        'fecha': Timestamp.now(),
        'total': _calcularTotal(),
        'estado': 'Pendiente',
        'productos': widget.carrito.map((item) => {
          'nombre': item['nombre'],
          'precio': double.tryParse(item['precio'].toString()) ?? 0,
          'categoria': item['categoria'] ?? 'General',
          'cantidad': item['cantidad'] ?? 1,
        }).toList(),
      };

      await pedidoRef.set(pedido);
      
      widget.onVaciarCarrito();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Pedido realizado con éxito')),
      );
      
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al realizar pedido: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final total = _calcularTotal();
    final totalProductos = _calcularTotalProductos();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (widget.carrito.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Vaciar carrito'),
                    content: const Text('¿Estás seguro de que quieres vaciar el carrito?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.onVaciarCarrito();
                          Navigator.pop(context);
                        },
                        child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Resumen del pedido
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.brown.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalProductos productos',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total: S/ ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                if (widget.carrito.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _realizarPedido,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_cart_checkout),
                    label: Text(_isLoading ? 'Procesando...' : 'Realizar Pedido'),
                  ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: widget.carrito.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Tu carrito está vacío',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.carrito.length,
                    itemBuilder: (context, index) {
                      final item = widget.carrito[index];
                      final precio = double.tryParse(item['precio'].toString()) ?? 0;
                      final cantidad = item['cantidad'] ?? 1;
                      final subtotal = precio * cantidad;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.brown.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                cantidad.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                          ),
                          title: Text(item['nombre'] ?? 'Producto'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('S/ ${precio.toStringAsFixed(2)} c/u'),
                              Text(
                                'Subtotal: S/ ${subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 20),
                                onPressed: () => widget.onDisminuirCantidad(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 20),
                                onPressed: () => widget.onAumentarCantidad(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => widget.onEliminarDelCarrito(index),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}