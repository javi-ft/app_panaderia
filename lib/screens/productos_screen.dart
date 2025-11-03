import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'tienda_screen.dart';

class ProductosScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final void Function(Map<String, dynamic>) onAgregarAlCarrito;
  final void Function(int) onEliminarDelCarrito;
  final VoidCallback onVaciarCarrito;
  final void Function(int) onAumentarCantidad;
  final void Function(int) onDisminuirCantidad;
  final double Function() calcularTotal;

  const ProductosScreen({
    super.key,
    required this.carrito,
    required this.onAgregarAlCarrito,
    required this.onEliminarDelCarrito,
    required this.onVaciarCarrito,
    required this.onAumentarCantidad,
    required this.onDisminuirCantidad,
    required this.calcularTotal,
  });

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> with TickerProviderStateMixin {
  String busqueda = '';
  late AnimationController _carritoAnimController;
  final TextEditingController _busquedaController = TextEditingController();
  String _categoriaSeleccionada = 'Todos';
  List<String> _categorias = ['Todos'];

  @override
  void initState() {
    super.initState();
    _carritoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.8,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _carritoAnimController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  String convertirEnlaceDriveADirecto(String enlaceDrive) {
    final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(enlaceDrive);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$id&w=150&h=150';
    } else {
      return enlaceDrive;
    }
  }

  void _animarCarrito() {
    _carritoAnimController.forward(from: 0.0).then((_) {
      _carritoAnimController.reverse();
    });
  }

  void _navegarATienda() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TiendaScreen(
          carrito: widget.carrito,
          onEliminarDelCarrito: widget.onEliminarDelCarrito,
          onVaciarCarrito: widget.onVaciarCarrito,
          onAumentarCantidad: widget.onAumentarCantidad,
          onDisminuirCantidad: widget.onDisminuirCantidad,
          total: widget.calcularTotal(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImagen() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.bakery_dining, color: Colors.brown, size: 25),
    );
  }

  Widget _buildCategoriaChip(String categoria, bool seleccionada) {
    return GestureDetector(
      onTap: () {
        setState(() => _categoriaSeleccionada = categoria);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionada ? Colors.brown : Colors.brown.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionada ? Colors.brown : Colors.brown.shade200,
          ),
        ),
        child: Text(
          categoria,
          style: TextStyle(
            color: seleccionada ? Colors.white : Colors.brown,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (valor) => setState(() => busqueda = valor.toLowerCase().trim()),
            ),
          ),

          // Categorías deslizables
          SizedBox(
            height: 50,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('productos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final productos = snapshot.data!.docs;
                  
                  // Obtener categorías únicas
                  final categoriasSet = <String>{'Todos'};
                  for (var doc in productos) {
                    final data = doc.data() as Map<String, dynamic>;
                    final categoria = data['categoria'] ?? 'Sin categoria';
                    categoriasSet.add(categoria);
                  }
                  
                  _categorias = categoriasSet.toList();
                  
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categorias.length,
                    itemBuilder: (context, index) {
                      final categoria = _categorias[index];
                      return _buildCategoriaChip(
                        categoria, 
                        categoria == _categoriaSeleccionada
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),

          const SizedBox(height: 8),

          // Lista de productos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('productos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final productos = snapshot.data!.docs;
                
                // Filtrar por categoría y búsqueda
                final productosFiltrados = productos.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                  final descripcion = (data['descripcion'] ?? '').toString().toLowerCase();
                  final categoria = data['categoria'] ?? 'Sin categoria';
                  
                  // Filtro por categoría
                  if (_categoriaSeleccionada != 'Todos' && categoria != _categoriaSeleccionada) {
                    return false;
                  }
                  
                  // Filtro por búsqueda
                  if (busqueda.isNotEmpty && 
                      !nombre.contains(busqueda) && 
                      !descripcion.contains(busqueda)) {
                    return false;
                  }
                  
                  return true;
                }).toList();

                if (productosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          busqueda.isEmpty 
                            ? 'No hay productos en ${
                                _categoriaSeleccionada == 'Todos' 
                                  ? 'ninguna categoria' 
                                  : _categoriaSeleccionada
                              }'
                            : 'No se encontraron productos para "$busqueda"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    final doc = productosFiltrados[index];
                    final producto = doc.data() as Map<String, dynamic>;
                    final urlImagenOriginal = producto['imagen'] ?? '';
                    final urlImagenDirecta = convertirEnlaceDriveADirecto(urlImagenOriginal);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: urlImagenOriginal.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: urlImagenDirecta,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  progressIndicatorBuilder: (context, url, progress) => _buildPlaceholderImagen(),
                                  errorWidget: (context, url, error) => _buildPlaceholderImagen(),
                                ),
                              )
                            : _buildPlaceholderImagen(),
                        title: Text(
                          producto['nombre'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (producto['descripcion'] != null)
                              Text(
                                producto['descripcion'],
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'S/ ${double.tryParse(producto['precio'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          color: Colors.brown,
                          onPressed: () {
                            widget.onAgregarAlCarrito(producto);
                            _animarCarrito();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ ${producto['nombre']} agregado al carrito'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _carritoAnimController, curve: Curves.elasticOut),
        child: FloatingActionButton(
          onPressed: _navegarATienda,
          backgroundColor: Colors.brown,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white),
              if (widget.carrito.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      widget.carrito.length.toString(),
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
        ),
      ),
    );
  }
}