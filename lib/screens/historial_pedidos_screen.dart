import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialPedidosScreen extends StatelessWidget {
  final List<Map<String, dynamic>> carrito;

  const HistorialPedidosScreen({super.key, required this.carrito});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Debes iniciar sesión para ver tu historial de pedidos 🧾'),
        ),
      );
    }

    // ✅ CORREGIDO: Cambiado de 'Pedidos' a 'MisPedidos'
    final pedidosRef = FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(user.uid)
        .collection('MisPedidos')
        .orderBy('fecha', descending: true);

    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: const Text(
          'Historial de Pedidos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.brown.shade600,
        centerTitle: true,
        elevation: 3,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pedidosRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.brown));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 90, color: Colors.brown.shade200),
                  const SizedBox(height: 20),
                  const Text(
                    'No tienes pedidos realizados',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tus pedidos aparecerán aquí una vez realizados',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final pedidos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              final data = pedido.data() as Map<String, dynamic>;
              final productos = List<Map<String, dynamic>>.from(data['productos'] ?? []);
              final total = (data['total'] ?? 0.0).toDouble();
              final fecha = (data['fecha'] as Timestamp).toDate();
              final estado = (data['estado'] ?? 'Pendiente').toString();
              final numeroPedido = data['numeroPedido'] ?? 'N/A';

              // tarjeta principal
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.shade100.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      _openDetallePedido(context, data, index);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          // icono izquierdo
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.brown.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              color: Colors.brown.shade700,
                              size: 30,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // columna central (título + fecha + total)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pedido #$numeroPedido',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Fecha: ${_formatFecha(fecha)}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Total: S/ ${total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // columna derecha: estado + ver detalles
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // botón Estado
                              ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Estado: $estado')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _getColorEstado(estado),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  minimumSize: const Size(0, 0),
                                ),
                                child: Text(
                                  estado,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Ver detalles
                              TextButton(
                                onPressed: () => _openDetallePedido(context, data, index),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                child: Text(
                                  'Ver detalles',
                                  style: TextStyle(
                                    color: Colors.brown.shade700,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openDetallePedido(BuildContext context, Map<String, dynamic> data, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final productos = List<Map<String, dynamic>>.from(data['productos'] ?? []);
        final total = (data['total'] ?? 0.0).toDouble();
        final estado = data['estado'] ?? 'Pendiente';
        final fecha = (data['fecha'] as Timestamp).toDate();
        final numeroPedido = data['numeroPedido'] ?? 'N/A';
        final subtotal = (data['subtotal'] ?? 0.0).toDouble();
        final impuestos = (data['impuestos'] ?? 0.0).toDouble();
        final costoEnvio = (data['costoEnvio'] ?? 0.0).toDouble();
        final metodoPago = data['metodoPago'] ?? 'No especificado';

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (_, controller) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Pedido #$numeroPedido', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Chip(
                      label: Text(estado, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: _getColorEstado(estado),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text('Fecha: ${_formatFecha(fecha)}', style: TextStyle(color: Colors.grey.shade700)),
                Text('Método de pago: ${_formatearMetodoPago(metodoPago)}', style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                
                // Detalles de precios
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildLineaPrecio('Subtotal', subtotal),
                      _buildLineaPrecio('Impuestos (18%)', impuestos),
                      _buildLineaPrecio('Costo de envío', costoEnvio),
                      const Divider(),
                      _buildLineaPrecio('TOTAL', total, isTotal: true),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Productos:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      ...productos.map((producto) {
                        final cantidad = producto['cantidad'] ?? 1;
                        final precio = (producto['precio'] ?? 0).toDouble();
                        final nombre = producto['nombre'] ?? 'Producto';
                        final categoria = producto['categoria'] ?? 'General';
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.brown.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getIconoCategoria(categoria),
                                color: Colors.brown.shade700,
                                size: 24,
                              ),
                            ),
                            title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cantidad: $cantidad', style: TextStyle(color: Colors.grey.shade600)),
                                Text('Categoría: $categoria', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                            trailing: Text(
                              'S/ ${(precio * cantidad).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)
                            ),
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 16),
                      
                      // botón repetir pedido
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Funcionalidad de repetir pedido en desarrollo'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Repetir pedido'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget auxiliar para mostrar líneas de precio
  Widget _buildLineaPrecio(String label, double valor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.brown : Colors.grey.shade700,
            ),
          ),
          Text(
            'S/ ${valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // Ícono según categoría del producto
  IconData _getIconoCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'bebidas':
        return Icons.local_drink;
      case 'comida':
      case 'alimentos':
        return Icons.restaurant;
      case 'postres':
        return Icons.cake;
      case 'ensaladas':
        return Icons.eco;
      case 'sopas':
        return Icons.soup_kitchen;
      default:
        return Icons.fastfood;
    }
  }

  // Formatear método de pago
  String _formatearMetodoPago(String metodo) {
    switch (metodo) {
      case 'tarjeta':
        return 'Tarjeta de crédito/débito';
      case 'yape':
        return 'Yape / Plin';
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia bancaria';
      default:
        return metodo;
    }
  }

  // color por estado
  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmado':
      case 'completado':
        return Colors.green;
      case 'procesando':
      case 'en preparación':
        return Colors.orange;
      case 'en camino':
      case 'enviado':
        return Colors.blue;
      case 'pendiente':
        return Colors.grey;
      default:
        return Colors.brown;
    }
  }

  // formato de fecha
  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}