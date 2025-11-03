import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TiendaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final void Function(int) onEliminarDelCarrito;
  final VoidCallback onVaciarCarrito;
  final void Function(int) onAumentarCantidad;
  final void Function(int) onDisminuirCantidad;
  final double total;

  const TiendaScreen({
    super.key,
    required this.carrito,
    required this.onEliminarDelCarrito,
    required this.onVaciarCarrito,
    required this.onAumentarCantidad,
    required this.onDisminuirCantidad,
    required this.total,
  });

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  bool _mostrarCarrito = false;

  // 🗺️ FUNCIÓN PARA ABRIR GOOGLE MAPS
  void _abrirGoogleMaps() async {
    final String url = 'https://www.google.com/maps/place/Pasteleria+Flori/@-12.0735,-75.1905228,19z/data=!4m6!3m5!1s0x910e97a01ac1e751:0x5e561a56991e7a76!8m2!3d-12.0728896!4d-75.1900345!16s%2Fg%2F11jgscw15h?entry=ttu&g_ep=EgoyMDI1MTAyMi4wIKXMDSoASAFQAw%3D%3D';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _mostrarMensaje('No se pudo abrir Google Maps');
    }
  }

  // 🧭 FUNCIÓN PARA ABRIR WAZE
  void _abrirWaze() async {
    final String url = 'https://waze.com/ul?q=Panaderia%20Delicia%20Lima%20Peru&navigate=yes';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _mostrarMensaje('No se pudo abrir Waze');
    }
  }

  // 📞 FUNCIÓN PARA LLAMAR
  void _llamarTienda() async {
    final url = Uri.parse('tel:+51944975522');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _mostrarMensaje('No se pudo realizar la llamada');
    }
  }

  // 💬 FUNCIÓN PARA WHATSAPP
  void _enviarWhatsApp() async {
    final message = 'Hola, quiero información de sus productos de panadería';
    final url = Uri.parse('https://wa.me/51944975522?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _mostrarMensaje('No se pudo abrir WhatsApp');
    }
  }

  // 📧 FUNCIÓN PARA CORREO
  void _enviarCorreo() async {
    final url = Uri.parse('mailto:pan_pas_flori@gmail.com?subject=Consulta&body=Hola, me gustaría obtener información sobre sus productos');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _mostrarMensaje('No se pudo abrir la app de correo');
    }
  }

  // 🎯 FUNCIÓN PARA MOSTRAR OPCIONES DE NAVEGACIÓN
  void _mostrarOpcionesNavegacion() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cómo quieres llegar?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 20),
              
              _buildActionButton(
                icon: Icons.map_outlined,
                iconColor: Colors.red,
                title: 'Abrir en Google Maps',
                subtitle: 'Navegación paso a paso',
                onTap: _abrirGoogleMaps,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                ),
              ),
              
              const SizedBox(height: 12),
              
              _buildActionButton(
                icon: Icons.navigation_outlined,
                iconColor: Colors.white,
                title: 'Abrir en Waze',
                subtitle: 'Rutas en tiempo real',
                onTap: _abrirWaze,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3366CC), Color(0xFF00C7FF)],
                ),
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 WIDGET PARA BOTONES DE ACCIÓN ESTILIZADOS
  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Gradient gradient,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 WIDGET PARA TARJETAS DE INFORMACIÓN MODERNAS
  Widget _buildInfoCardModern({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> actionButtons,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.brown.shade50,
            Colors.white,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.brown.shade400,
                        Colors.brown.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actionButtons,
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 WIDGET PARA BOTONES PEQUEÑOS ESTILIZADOS
  Widget _buildSmallButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(15),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 WIDGET PARA CHIPS DE SERVICIOS MODERNOS
  Widget _buildServiceChipModern(String text, VoidCallback onTap) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade50,
              Colors.brown.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_outline,
                    color: Colors.brown.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.brown.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarInfoDelivery() {
    _mostrarDialogoInformacion(
      titulo: "🚚 Delivery Gratis",
      contenido: "• Delivery gratis en compras mayores a S/ 30\n"
          "• Zona de cobertura: 5km a la redonda\n"
          "• Tiempo de entrega: 30-45 minutos\n"
          "• Horario: 8:00 AM - 9:00 PM",
    );
  }

  void _mostrarInfoPedidosEspeciales() {
    _mostrarDialogoInformacion(
      titulo: "🎂 Pedidos Especiales",
      contenido: "• Tortas personalizadas para cumpleaños\n"
          "• Pasteles para bodas y eventos\n"
          "• Panetones navideños\n"
          "• Pedidos con 48 horas de anticipación\n"
          "• Consulta por diseños y sabores",
      botonAccion: _enviarWhatsApp,
      textoBoton: "Pedir por WhatsApp",
    );
  }

  void _mostrarInfoMetodosPago() {
    _mostrarDialogoInformacion(
      titulo: "💳 Métodos de Pago",
      contenido: "Aceptamos los siguientes métodos de pago:\n\n"
          "• Efectivo\n• Tarjetas de crédito/débito\n• Yape / Plin\n"
          "• Transferencia bancaria\n• Pago contra entrega",
    );
  }

  void _mostrarInfoCatering() {
    _mostrarDialogoInformacion(
      titulo: "📦 Catering para Eventos",
      contenido: "Servicio de catering para eventos:\n\n"
          "• Desayunos empresariales\n• Coffee breaks\n"
          "• Cumpleaños infantiles y adultos\n• Bodas y aniversarios\n"
          "• Eventos corporativos\n\nMínimo 20 personas",
      botonAccion: _llamarTienda,
      textoBoton: "Llamar para cotizar",
    );
  }

  void _mostrarDialogoInformacion({
    required String titulo,
    required String contenido,
    VoidCallback? botonAccion,
    String? textoBoton,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.orange.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  contenido,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Cerrar'),
                      ),
                    ),
                    if (botonAccion != null && textoBoton != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            botonAccion();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 4,
                          ),
                          child: Text(textoBoton),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.brown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  void _realizarPedido() {
    if (widget.carrito.isEmpty) {
      _mostrarMensaje("El carrito está vacío");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.orange.shade50],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_cart_checkout,
                    color: Colors.brown,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Confirmar Pedido",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Total: S/ ${_calcularTotal().toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Productos: ${_calcularTotalProductos()}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _mostrarMensaje("✅ Pedido realizado con éxito!");
                          widget.onVaciarCarrito();
                          setState(() => _mostrarCarrito = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 4,
                        ),
                        child: const Text('Confirmar'),
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

  // 🎨 WIDGET PARA ITEM DEL CARRITO - CORREGIDO
  Widget _buildCarritoItem(int index, Map<String, dynamic> item) {
    final precio = double.tryParse(item['precio'].toString()) ?? 0;
    final cantidad = item['cantidad'] ?? 1;
    final subtotal = precio * cantidad;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.brown.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              cantidad.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
          ),
        ),
        title: Text(
          item['nombre'] ?? 'Producto',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'S/ ${precio.toStringAsFixed(2)} x $cantidad = S/ ${subtotal.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBotonAccion(
              icon: Icons.remove,
              color: Colors.red,
              onPressed: () => _manejarDisminuirCantidad(index),
            ),
            const SizedBox(width: 8),
            _buildBotonAccion(
              icon: Icons.add,
              color: Colors.green,
              onPressed: () => _manejarAumentarCantidad(index),
            ),
            const SizedBox(width: 8),
            _buildBotonAccion(
              icon: Icons.delete_outline,
              color: Colors.grey,
              onPressed: () => _manejarEliminarProducto(index),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 WIDGET CORREGIDO - SIN .shade50
  Widget _buildBotonAccion({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        color: color,
        padding: const EdgeInsets.all(6),
      ),
    );
  }

  void _manejarAumentarCantidad(int index) {
    if (index >= 0 && index < widget.carrito.length) {
      widget.onAumentarCantidad(index);
      setState(() {
        // Forzar la actualización del estado
      });
    }
  }

  void _manejarDisminuirCantidad(int index) {
    if (index >= 0 && index < widget.carrito.length) {
      final item = widget.carrito[index];
      final cantidadActual = item['cantidad'] ?? 1;
      
      if (cantidadActual > 1) {
        widget.onDisminuirCantidad(index);
        setState(() {
          // Forzar la actualización del estado
        });
      } else {
        _manejarEliminarProducto(index);
      }
    }
  }

  void _manejarEliminarProducto(int index) {
    if (index >= 0 && index < widget.carrito.length) {
      widget.onEliminarDelCarrito(index);
      setState(() {
        // Forzar la actualización del estado
      });
      
      if (widget.carrito.isEmpty) {
        setState(() => _mostrarCarrito = false);
      }
    }
  }

  // 🧮 FUNCIONES PARA CALCULAR TOTALES ACTUALIZADOS
  // 🧮 FUNCIONES PARA CALCULAR TOTALES ACTUALIZADOS
double _calcularTotal() {
  double total = 0;
  for (var item in widget.carrito) {
    final precio = double.tryParse(item['precio'].toString()) ?? 0;
    final dynamic cantidad = item['cantidad'] ?? 1;
    
    // Manejar diferentes tipos de cantidad
    if (cantidad is int) {
      total += precio * cantidad;
    } else if (cantidad is double) {
      total += precio * cantidad;
    } else {
      total += precio * (int.tryParse(cantidad.toString()) ?? 1);
    }
  }
  return total;
}

int _calcularTotalProductos() {
  int totalProductos = 0;
  for (var item in widget.carrito) {
    final dynamic cantidad = item['cantidad'] ?? 1;
    
    // Manejar diferentes tipos de cantidad
    if (cantidad is int) {
      totalProductos += cantidad;
    } else if (cantidad is double) {
      totalProductos += cantidad.toInt();
    } else {
      totalProductos += int.tryParse(cantidad.toString()) ?? 1;
    }
  }
  return totalProductos;
}
  @override
  Widget build(BuildContext context) {
    final totalActual = _calcularTotal();
    final totalProductos = _calcularTotalProductos();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("FLORI"),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER MODERNO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.brown.shade600,
                    Colors.orange.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Nuestra Tienda",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Desde 2020 sirviendo la mejor calidad",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // TARJETA DE UBICACIÓN MODERNA
            _buildInfoCardModern(
              icon: Icons.location_on,
              title: "Ubicación",
              subtitle: "Av. Leoncio Prado Gutierrez #103, Huancayo, Perú",
              actionButtons: [
                _buildSmallButton(
                  icon: Icons.map,
                  label: "Ver Mapa",
                  onPressed: _mostrarOpcionesNavegacion,
                  color: Colors.red.shade400,
                ),
                _buildSmallButton(
                  icon: Icons.navigation,
                  label: "Waze",
                  onPressed: _abrirWaze,
                  color: Colors.blue.shade400,
                ),
              ],
            ),

            // TARJETA DE CONTACTO MODERNA
            _buildInfoCardModern(
              icon: Icons.phone,
              title: "Contacto",
              subtitle: "+51 944 975 522 | pan_pas_flori@gmail.com",
              actionButtons: [
                _buildSmallButton(
                  icon: Icons.phone,
                  label: "Llamar",
                  onPressed: _llamarTienda,
                  color: Colors.green.shade400,
                ),
                _buildSmallButton(
                  icon: Icons.chat,
                  label: "WhatsApp",
                  onPressed: _enviarWhatsApp,
                  color: Colors.green.shade600,
                ),
                _buildSmallButton(
                  icon: Icons.email,
                  label: "Email",
                  onPressed: _enviarCorreo,
                  color: Colors.blue.shade600,
                ),
              ],
            ),

            // TARJETA DE HORARIO MODERNA
            _buildInfoCardModern(
              icon: Icons.access_time,
              title: "Horario de Atención",
              subtitle: "Lunes a Domingo • 6:00 AM - 10:00 PM",
              actionButtons: [
                _buildSmallButton(
                  icon: Icons.shopping_cart,
                  label: "Pedir Ahora",
                  onPressed: _enviarWhatsApp,
                  color: Colors.orange.shade400,
                ),
              ],
            ),

            const SizedBox(height: 25),

            // SERVICIOS
            const Text(
              "🌟 Nuestros Servicios",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildServiceChipModern("🚚 Delivery Gratis", _mostrarInfoDelivery),
                _buildServiceChipModern("🎂 Pedidos Especiales", _mostrarInfoPedidosEspeciales),
                _buildServiceChipModern("💳 Tarjetas Crédito/Débito", _mostrarInfoMetodosPago),
                _buildServiceChipModern("📦 Catering para Eventos", _mostrarInfoCatering),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),

      // CARRITO MEJORADO
      bottomSheet: _mostrarCarrito ? _buildCarritoPanel(totalActual, totalProductos) : null,

      // FLOATING ACTION BUTTON MODERNO
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          onPressed: () => setState(() => _mostrarCarrito = !_mostrarCarrito),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Badge(
            label: Text(totalProductos.toString()),
            isLabelVisible: widget.carrito.isNotEmpty,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            child: const Icon(Icons.shopping_cart),
          ),
          label: Text(
            'Carrito • S/ ${totalActual.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 🛒 PANEL DEL CARRITO MODERNO - ACTUALIZADO
  Widget _buildCarritoPanel(double totalActual, int totalProductos) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del carrito
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.brown.shade600,
                  Colors.orange.shade400,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Tu Carrito',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'S/ ${totalActual.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$totalProductos productos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _mostrarCarrito = false),
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
                        SizedBox(height: 8),
                        Text(
                          'Agrega algunos productos',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.carrito.length,
                    itemBuilder: (context, index) {
                      final item = widget.carrito[index];
                      return _buildCarritoItem(index, item);
                    },
                  ),
          ),
          
          // Botones de acción del carrito
          if (widget.carrito.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        widget.onVaciarCarrito();
                        setState(() => _mostrarCarrito = false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Vaciar Todo'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _realizarPedido,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Realizar Pedido'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}