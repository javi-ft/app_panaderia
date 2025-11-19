import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
  final _formatter = NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cálculos optimizados
  double get _subtotal => widget.carrito.fold(0, (sum, item) {
        final precio = double.tryParse(item['precio'].toString()) ?? 0;
        final cantidad = item['cantidad'] ?? 1;
        return sum + (precio * cantidad);
      });

  double get _impuestos => _subtotal * 0.18;
  double get _costoEnvio => _subtotal > 50 ? 0 : 8.90;
  double get _total => _subtotal + _impuestos + _costoEnvio;

  int get _totalProductos => widget.carrito.fold(0, (sum, item) {
        final cantidad = item['cantidad'] ?? 1;
        return sum + (cantidad is int ? cantidad : int.tryParse(cantidad.toString()) ?? 1);
      });

  bool get _puedeRealizarPedido => widget.carrito.isNotEmpty && !_isLoading;

  @override
  void initState() {
    super.initState();
    print('Carrito inicializado con ${widget.carrito.length} productos');
  }

  void _actualizarEstado() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _realizarPedido() async {
    final user = _auth.currentUser;
    if (user == null) {
      _mostrarError('Debes iniciar sesión para realizar un pedido');
      return;
    }

    if (!_puedeRealizarPedido) return;

    // Mostrar opciones de pago primero
    final metodoPago = await _mostrarOpcionesPago();
    if (metodoPago == null) return;

    setState(() => _isLoading = true);

    try {
      // VERIFICAR DATOS DEL CARRITO
      print('=== INICIANDO PEDIDO ===');
      print('Productos en carrito: ${widget.carrito.length}');
      for (var i = 0; i < widget.carrito.length; i++) {
        var item = widget.carrito[i];
        print('Producto $i: ${item['nombre']}, ID: ${item['id']}, Precio: ${item['precio']}, Cantidad: ${item['cantidad']}');
      }

      // Procesar el pago según el método seleccionado
      final pagoExitoso = await _procesarPago(metodoPago);
      if (!pagoExitoso) {
        setState(() => _isLoading = false);
        return;
      }

      // Si el pago fue exitoso, guardar el pedido
      final numeroPedido = _generarNumeroPedido();
      
      // PREPARAR PRODUCTOS CON ESTRUCTURA CORRECTA
      List<Map<String, dynamic>> productosParaPedido = [];
      
      for (var item in widget.carrito) {
        // Convertir y validar datos
        double precio = 0.0;
        if (item['precio'] is double) {
          precio = item['precio'];
        } else if (item['precio'] is int) {
          precio = (item['precio'] as int).toDouble();
        } else {
          precio = double.tryParse(item['precio'].toString()) ?? 0.0;
        }
        
        int cantidad = 1;
        if (item['cantidad'] is int) {
          cantidad = item['cantidad'];
        } else {
          cantidad = int.tryParse(item['cantidad'].toString()) ?? 1;
        }
        
        Map<String, dynamic> producto = {
          'id': item['id']?.toString() ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
          'nombre': item['nombre']?.toString() ?? 'Producto sin nombre',
          'precio': precio,
          'categoria': item['categoria']?.toString() ?? 'General',
          'cantidad': cantidad,
          'imagen': item['imagen']?.toString() ?? '',
          'subtotal': precio * cantidad,
        };
        
        productosParaPedido.add(producto);
      }

      // Calcular totales
      final subtotalCalculado = productosParaPedido.fold(0.0, (sum, item) => sum + (item['subtotal'] as double));
      final impuestosCalculados = subtotalCalculado * 0.18;
      final costoEnvioCalculado = subtotalCalculado > 50 ? 0 : 8.90;
      final totalCalculado = subtotalCalculado + impuestosCalculados + costoEnvioCalculado;

      // ESTRUCTURA CORREGIDA DEL PEDIDO
      final pedidoData = {
        'id': numeroPedido,
        'numeroPedido': numeroPedido,
        'fecha': FieldValue.serverTimestamp(),
        'subtotal': subtotalCalculado,
        'impuestos': impuestosCalculados,
        'costoEnvio': costoEnvioCalculado,
        'total': totalCalculado,
        'estado': 'confirmado',
        'metodoPago': metodoPago,
        'estadoPago': 'completado',
        'fechaPago': FieldValue.serverTimestamp(),
        'direccionEnvio': _obtenerDireccionUsuario(),
        'productos': productosParaPedido,
        'numeroItems': _totalProductos,
        'usuarioId': user.uid, // Campo adicional para consultas
        'usuario': {
          'uid': user.uid,
          'email': user.email ?? '',
          'nombre': user.displayName ?? 'Cliente',
        },
        'tracking': {
          'estado': 'procesando',
          'fechaProcesamiento': FieldValue.serverTimestamp(),
          'fechaEstimadaEntrega': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 3))
          ),
        },
        'fechaCreacion': FieldValue.serverTimestamp(),
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      };

      print('=== GUARDANDO PEDIDO ===');
      print('Número de pedido: $numeroPedido');
      print('Total productos: ${productosParaPedido.length}');
      print('Total a pagar: $totalCalculado');

      // GUARDAR EN LA COLECCIÓN PRINCIPAL DE PEDIDOS
      await _firestore.collection('Pedidos').doc(numeroPedido).set(pedidoData);
      print('✅ Pedido guardado en colección Pedidos');

      // GUARDAR EN EL HISTORIAL DEL USUARIO
      await _firestore
          .collection('Usuarios')
          .doc(user.uid)
          .collection('MisPedidos')
          .doc(numeroPedido)
          .set(pedidoData);
      print('✅ Pedido guardado en historial del usuario');

      // VERIFICAR QUE SE GUARDÓ CORRECTAMENTE
      await _verificarPedidoGuardado(numeroPedido, user.uid);

      // Mostrar confirmación de éxito
      await _mostrarConfirmacionExito(numeroPedido, metodoPago);
      
      // Vaciar carrito solo si todo salió bien
      widget.onVaciarCarrito();
      
      if (mounted) {
        Navigator.pop(context);
      }
      
    } on FirebaseException catch (e) {
      print('❌ Error Firebase: ${e.code} - ${e.message}');
      _mostrarError('Error al procesar el pedido: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Error inesperado: $e');
      print('Stack trace: $stackTrace');
      _mostrarError('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // FUNCIÓN PARA VERIFICAR QUE EL PEDIDO SE GUARDÓ
  Future<void> _verificarPedidoGuardado(String numeroPedido, String userId) async {
    try {
      // Verificar en Pedidos generales
      final pedidoGeneral = await _firestore.collection('Pedidos').doc(numeroPedido).get();
      print('📋 Pedido en colección general: ${pedidoGeneral.exists}');
      
      // Verificar en historial del usuario
      final pedidoUsuario = await _firestore
          .collection('Usuarios')
          .doc(userId)
          .collection('MisPedidos')
          .doc(numeroPedido)
          .get();
      print('👤 Pedido en historial usuario: ${pedidoUsuario.exists}');
      
      if (pedidoGeneral.exists && pedidoUsuario.exists) {
        print('🎉 ✅ Pedido guardado correctamente en ambas ubicaciones');
      } else {
        print('❌ Error: Pedido no se guardó completamente');
      }
    } catch (e) {
      print('❌ Error al verificar pedido: $e');
    }
  }

  Future<bool> _procesarPago(String metodoPago) async {
    switch (metodoPago) {
      case 'tarjeta':
        return await _procesarPagoTarjeta();
      case 'yape':
        return await _procesarPagoYape();
      case 'efectivo':
        return await _procesarPagoEfectivo();
      case 'transferencia':
        return await _procesarPagoTransferencia();
      default:
        return false;
    }
  }

  Future<bool> _procesarPagoTarjeta() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TarjetaPagoDialog(
        total: _total,
        onPagoExitoso: () => Navigator.of(context).pop(true),
        onPagoFallido: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  Future<bool> _procesarPagoYape() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => YapePagoDialog(
        total: _total,
        onPagoExitoso: () => Navigator.of(context).pop(true),
        onPagoFallido: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  Future<bool> _procesarPagoEfectivo() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EfectivoPagoDialog(
        total: _total,
        onConfirmar: () => Navigator.of(context).pop(true),
        onCancelar: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  Future<bool> _procesarPagoTransferencia() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TransferenciaPagoDialog(
        total: _total,
        onConfirmar: () => Navigator.of(context).pop(true),
        onCancelar: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  Future<void> _mostrarConfirmacionExito(String numeroPedido, String metodoPago) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmacionExitoDialog(
        numeroPedido: numeroPedido,
        total: _total,
        metodoPago: metodoPago,
        fechaEstimada: DateTime.now().add(const Duration(days: 3)),
        onAceptar: () => Navigator.of(context).pop(),
      ),
    );
  }

  String _generarNumeroPedido() {
    final now = DateTime.now();
    final fecha = DateFormat('yyMMdd').format(now);
    final random = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'PED$fecha$random';
  }

  Future<String?> _mostrarOpcionesPago() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Seleccionar método de pago',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOpcionPago(
                context,
                'Tarjeta de crédito/débito',
                Icons.credit_card,
                'Pago seguro con tarjeta',
                'tarjeta',
              ),
              _buildOpcionPago(
                context,
                'Yape / Plin',
                Icons.phone_android,
                'Pago instantáneo',
                'yape',
              ),
              _buildOpcionPago(
                context,
                'Efectivo',
                Icons.money,
                'Pago al recibir',
                'efectivo',
              ),
              _buildOpcionPago(
                context,
                'Transferencia bancaria',
                Icons.account_balance,
                'Transferencia interbancaria',
                'transferencia',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionPago(BuildContext context, String titulo, IconData icono, String subtitulo, String valor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: Theme.of(context).primaryColor),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitulo, style: TextStyle(color: Colors.grey.shade600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.of(context).pop(valor),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Map<String, dynamic> _obtenerDireccionUsuario() {
    // En una app real, esto debería venir de Firestore o de un formulario
    return {
      'direccion': 'Av. Ejemplo 123',
      'ciudad': 'Lima',
      'distrito': 'Miraflores',
      'referencia': 'Frente al parque',
      'telefono': '+51 999 999 999',
      'codigoPostal': '15074',
    };
  }

  void _mostrarDialogoVaciarCarrito() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los productos del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onVaciarCarrito();
              Navigator.of(context).pop();
              _mostrarExito('Carrito vaciado');
              _actualizarEstado();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Vaciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _eliminarProducto(int index) {
    final producto = widget.carrito[index]['nombre'] ?? 'Producto';
    widget.onEliminarDelCarrito(index);
    _mostrarExito('$producto eliminado del carrito');
    _actualizarEstado();
  }

  void _aumentarCantidad(int index) {
    widget.onAumentarCantidad(index);
    _actualizarEstado();
  }

  void _disminuirCantidad(int index) {
    widget.onDisminuirCantidad(index);
    _actualizarEstado();
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_totalProductos ${_totalProductos == 1 ? 'producto' : 'productos'}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatter.format(_total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _puedeRealizarPedido ? _realizarPedido : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.shopping_bag_outlined),
                label: Text(_isLoading ? 'Procesando...' : 'Comprar ahora'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_costoEnvio > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Envío:', style: TextStyle(color: Colors.grey)),
                Text(_formatter.format(_costoEnvio), style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Impuestos (18%):', style: TextStyle(color: Colors.grey)),
              Text(_formatter.format(_impuestos), style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 120,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            const Text(
              'Tu carrito está vacío',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Agrega algunos productos increíbles para comenzar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Seguir comprando'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(int index) {
    final item = widget.carrito[index];
    final precio = double.tryParse(item['precio'].toString()) ?? 0;
    final cantidad = item['cantidad'] ?? 1;
    final subtotal = precio * cantidad;
    final productoId = item['id']?.toString() ?? index.toString();
    final productoNombre = item['nombre'] ?? 'Producto';

    return Dismissible(
      key: Key('carrito_item_$productoId'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 30),
            SizedBox(width: 8),
            Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar producto'),
            content: Text('¿Eliminar "$productoNombre" del carrito?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _eliminarProducto(index);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Imagen del producto
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                    image: item['imagen'] != null && item['imagen'].toString().isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item['imagen']!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item['imagen'] == null || item['imagen'].toString().isEmpty
                      ? Icon(Icons.shopping_bag, color: Colors.grey.shade400, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productoNombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatter.format(precio),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Subtotal: ${_formatter.format(subtotal)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Controles de cantidad
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, size: 18, color: Colors.grey.shade700),
                            onPressed: () => _disminuirCantidad(index),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              cantidad.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, size: 18, color: Colors.grey.shade700),
                            onPressed: () => _aumentarCantidad(index),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: TextButton(
                        onPressed: () => _eliminarProducto(index),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline, size: 16),
                            SizedBox(width: 4),
                            Text('Eliminar', style: TextStyle(fontSize: 12)),
                          ],
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Carrito de Compras',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (widget.carrito.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _mostrarDialogoVaciarCarrito,
              tooltip: 'Vaciar carrito',
              color: Colors.red,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: widget.carrito.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: widget.carrito.length,
                    itemBuilder: (context, index) => _buildProductItem(index),
                  ),
          ),
        ],
      ),
    );
  }
}

// Los diálogos de pago se mantienen igual que en tu código original...

// Diálogos de pago especializados
class TarjetaPagoDialog extends StatefulWidget {
  final double total;
  final VoidCallback onPagoExitoso;
  final VoidCallback onPagoFallido;

  const TarjetaPagoDialog({
    super.key,
    required this.total,
    required this.onPagoExitoso,
    required this.onPagoFallido,
  });

  @override
  State<TarjetaPagoDialog> createState() => _TarjetaPagoDialogState();
}

class _TarjetaPagoDialogState extends State<TarjetaPagoDialog> {
  bool _procesando = false;
  final _numeroController = TextEditingController();
  final _vencimientoController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nombreController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pago con Tarjeta'),
      content: _procesando 
          ? _buildProcesando()
          : _buildFormularioTarjeta(),
      actions: _procesando 
          ? null
          : [
              TextButton(
                onPressed: widget.onPagoFallido,
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _procesarPago,
                child: const Text('Pagar ahora'),
              ),
            ],
    );
  }

  Widget _buildFormularioTarjeta() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total a pagar: S/ ${widget.total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _numeroController,
            decoration: const InputDecoration(
              labelText: 'Número de tarjeta',
              hintText: '1234 5678 9012 3456',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _vencimientoController,
                  decoration: const InputDecoration(
                    labelText: 'MM/AA',
                    hintText: '12/25',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre en la tarjeta',
              hintText: 'JUAN PEREZ',
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pago seguro y encriptado',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcesando() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        const Text('Procesando pago...'),
        const SizedBox(height: 10),
        Text(
          'S/ ${widget.total.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _procesarPago() async {
    if (_numeroController.text.isEmpty || 
        _vencimientoController.text.isEmpty || 
        _cvvController.text.isEmpty || 
        _nombreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos')),
      );
      return;
    }

    setState(() => _procesando = true);

    // Simular procesamiento de pago
    await Future.delayed(const Duration(seconds: 2));

    // Simular éxito
    widget.onPagoExitoso();
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _vencimientoController.dispose();
    _cvvController.dispose();
    _nombreController.dispose();
    super.dispose();
  }
}

class YapePagoDialog extends StatefulWidget {
  final double total;
  final VoidCallback onPagoExitoso;
  final VoidCallback onPagoFallido;

  const YapePagoDialog({
    super.key,
    required this.total,
    required this.onPagoExitoso,
    required this.onPagoFallido,
  });

  @override
  State<YapePagoDialog> createState() => _YapePagoDialogState();
}

class _YapePagoDialogState extends State<YapePagoDialog> {
  bool _procesando = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pago con Yape'),
      content: _procesando 
          ? _buildProcesando()
          : _buildInstruccionesYape(),
      actions: _procesando 
          ? null
          : [
              TextButton(
                onPressed: widget.onPagoFallido,
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _simularPagoYape,
                child: const Text('Ya pagué'),
              ),
            ],
    );
  }

  Widget _buildInstruccionesYape() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.qr_code, size: 50),
        ),
        const SizedBox(height: 20),
        Text(
          'S/ ${widget.total.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        const Text(
          'Instrucciones:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text('1. Abre la app de Yape'),
        const Text('2. Escanea el código QR'),
        const Text('3. Confirma el pago'),
        const Text('4. Presiona "Ya pagué"'),
        const SizedBox(height: 15),
        const Text(
          'Número Yape: 944 975 522',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProcesando() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        const Text('Verificando pago...'),
        const SizedBox(height: 10),
        Text(
          'S/ ${widget.total.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _simularPagoYape() async {
    setState(() => _procesando = true);
    await Future.delayed(const Duration(seconds: 2));
    widget.onPagoExitoso();
  }
}

class EfectivoPagoDialog extends StatelessWidget {
  final double total;
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;

  const EfectivoPagoDialog({
    super.key,
    required this.total,
    required this.onConfirmar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pago en Efectivo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.money, size: 60, color: Colors.green),
          const SizedBox(height: 20),
          Text(
            'Total a pagar:',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          Text(
            'S/ ${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          const Text(
            'Pagarás al momento de la entrega',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancelar,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: onConfirmar,
          child: const Text('Confirmar pedido'),
        ),
      ],
    );
  }
}

class TransferenciaPagoDialog extends StatelessWidget {
  final double total;
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;

  const TransferenciaPagoDialog({
    super.key,
    required this.total,
    required this.onConfirmar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transferencia Bancaria'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance, size: 60, color: Colors.blue),
          const SizedBox(height: 20),
          Text(
            'S/ ${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Datos para la transferencia:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildDatoBanco('Banco:', 'BCP'),
          _buildDatoBanco('Tipo de cuenta:', 'Ahorros'),
          _buildDatoBanco('Número de cuenta:', '191-45678901-0-45'),
          _buildDatoBanco('CCI:', '00219114567890104519'),
          _buildDatoBanco('Titular:', 'TIENDA ONLINE SAC'),
          const SizedBox(height: 15),
          const Text(
            'Envía el comprobante a: pagos@tienda.com',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancelar,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: onConfirmar,
          child: const Text('Ya transferí'),
        ),
      ],
    );
  }

  Widget _buildDatoBanco(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(valor, style: const TextStyle(fontFamily: 'Monospace')),
        ],
      ),
    );
  }
}

class ConfirmacionExitoDialog extends StatelessWidget {
  final String numeroPedido;
  final double total;
  final String metodoPago;
  final DateTime fechaEstimada;
  final VoidCallback onAceptar;

  const ConfirmacionExitoDialog({
    super.key,
    required this.numeroPedido,
    required this.total,
    required this.metodoPago,
    required this.fechaEstimada,
    required this.onAceptar,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 40, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Pago Exitoso!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Pedido #$numeroPedido',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Total pagado', 'S/ ${total.toStringAsFixed(2)}'),
            _buildInfoRow('Método de pago', _formatearMetodoPago(metodoPago)),
            _buildInfoRow(
              'Fecha estimada de entrega',
              DateFormat('dd/MM/yyyy').format(fechaEstimada),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recibirás una confirmación por correo electrónico',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAceptar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Aceptar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: const TextStyle(color: Colors.grey)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatearMetodoPago(String metodo) {
    switch (metodo) {
      case 'tarjeta': return 'Tarjeta de crédito/débito';
      case 'yape': return 'Yape / Plin';
      case 'efectivo': return 'Efectivo';
      case 'transferencia': return 'Transferencia bancaria';
      default: return metodo;
    }
  }
}