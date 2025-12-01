import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'carrito_screen.dart';

class ProductosScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final void Function(Map<String, dynamic>) onAgregarAlCarrito;
  final void Function(int) onEliminarDelCarrito;
  final VoidCallback onVaciarCarrito;
  final void Function(int) onAumentarCantidad;
  final void Function(int) onDisminuirCantidad;
  final double Function() calcularTotal;
  final void Function(Map<String, dynamic>) onAgregarAFavoritos;
  final bool Function(String) esFavorito;
  final ScrollController? scrollController;
  final Function(Map<String, dynamic>) onMostrarDetalles;

  const ProductosScreen({
    super.key,
    required this.carrito,
    required this.onAgregarAlCarrito,
    required this.onEliminarDelCarrito,
    required this.onVaciarCarrito,
    required this.onAumentarCantidad,
    required this.onDisminuirCantidad,
    required this.calcularTotal,
    required this.onAgregarAFavoritos,
    required this.esFavorito,
    required this.onMostrarDetalles,
    this.scrollController,
  });

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen>
    with TickerProviderStateMixin {
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
      return 'https://drive.google.com/uc?export=view&id=$id&w=300&h=300';
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
        builder: (_) => CarritoScreen(
          carrito: widget.carrito,
          onEliminarDelCarrito: widget.onEliminarDelCarrito,
          onVaciarCarrito: widget.onVaciarCarrito,
          onAumentarCantidad: widget.onAumentarCantidad,
          onDisminuirCantidad: widget.onDisminuirCantidad,
        ),
      ),
    );
  }

  Widget _buildPlaceholderImagen() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.brown.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.broken_image, color: Colors.brown, size: 50),
    );
  }

  Widget _buildCategoriaChip(String categoria, bool seleccionada) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _categoriaSeleccionada = categoria);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: seleccionada
                ? LinearGradient(
                    colors: [Colors.brown.shade600, Colors.brown.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: seleccionada ? null : Colors.brown.shade50,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: seleccionada ? Colors.brown.shade600 : Colors.brown.shade200,
              width: seleccionada ? 2 : 1,
            ),
            boxShadow: seleccionada
                ? [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            categoria,
            style: TextStyle(
              color: seleccionada ? Colors.white : Colors.brown.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductoCard(
    DocumentSnapshot doc, Map<String, dynamic> producto) {
  final urlImagenOriginal = producto['imagen'] ?? '';
  final urlImagenDirecta = convertirEnlaceDriveADirecto(urlImagenOriginal);
  final precio = double.tryParse(producto['precio'].toString()) ?? 0.0;
  final categoria = producto['categoria'] ?? 'General';
  final descripcion = producto['descripcion'] ?? '';
  final productoId = doc.id;
  final esFavorito = widget.esFavorito(productoId);

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          final productoConId = {
            ...producto,
            'id': productoId,
          };
          widget.onMostrarDetalles(productoConId);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con botón de favoritos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Categoría
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      categoria,
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Botón de favoritos
                  IconButton(
                    icon: Icon(
                      esFavorito ? Icons.favorite : Icons.favorite_border,
                      color: esFavorito ? Colors.pink : Colors.grey,
                      size: 28,
                    ),
                    onPressed: () {
                      final productoConId = {
                        ...producto,
                        'id': productoId,
                      };
                      widget.onAgregarAFavoritos(productoConId);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Imagen del producto
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: urlImagenOriginal.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: urlImagenDirecta,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            progressIndicatorBuilder:
                                (context, url, progress) =>
                                    _buildPlaceholderImagen(),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholderImagen(),
                          )
                        : _buildPlaceholderImagen(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Nombre del producto
              Text(
                producto['nombre'] ?? 'Sin nombre',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Descripción
              if (descripcion.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Precio y botón
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Precio:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'S/ ${precio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.brown.shade600, Colors.brown.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.brown.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        onTap: () {
                          final productoConId = {
                            ...producto,
                            'id': doc.id,
                          };
                          widget.onAgregarAlCarrito(productoConId);
                          _animarCarrito();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ ${producto['nombre']} agregado al carrito'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_shopping_cart,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Agregar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
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
      body: Column(
        children: [
          // Campo de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
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
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: '🔍 Buscar productos...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (valor) =>
                  setState(() => busqueda = valor.toLowerCase().trim()),
            ),
          ),

          // Categorías deslizables - CORREGIDO (HORIZONTAL)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: SizedBox(
              height: 50,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('productos')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final productos = snapshot.data!.docs;

                    final categoriasSet = <String>{'Todos'};
                    for (var doc in productos) {
                      final data = doc.data() as Map<String, dynamic>;
                      final categoria = data['categoria'] ?? 'Sin categoria';
                      categoriasSet.add(categoria);
                    }

                    _categorias = categoriasSet.toList();

                    // LISTVIEW HORIZONTAL CORREGIDO
                    return ListView.builder(
                      scrollDirection: Axis.horizontal, // ← ESTA ES LA CORRECCIÓN
                      itemCount: _categorias.length,
                      itemBuilder: (context, index) {
                        final categoria = _categorias[index];
                        return _buildCategoriaChip(
                            categoria, categoria == _categoriaSeleccionada);
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Lista de productos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('productos')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                final productos = snapshot.data!.docs;

                final productosFiltrados = productos.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre =
                      (data['nombre'] ?? '').toString().toLowerCase();
                  final descripcion =
                      (data['descripcion'] ?? '').toString().toLowerCase();
                  final categoria = data['categoria'] ?? 'Sin categoria';

                  if (_categoriaSeleccionada != 'Todos' &&
                      categoria != _categoriaSeleccionada) {
                    return false;
                  }

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
                        const Icon(Icons.search_off,
                            size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          busqueda.isEmpty
                              ? 'No hay productos en ${_categoriaSeleccionada == 'Todos' ? 'ninguna categoria' : _categoriaSeleccionada}'
                              : 'No se encontraron productos para "$busqueda"',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    final doc = productosFiltrados[index];
                    final producto = doc.data() as Map<String, dynamic>;
                    return _buildProductoCard(doc, producto);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}