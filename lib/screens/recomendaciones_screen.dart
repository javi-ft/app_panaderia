import 'package:flutter/material.dart';
import '../services/recomendacion_service.dart';
import '../models/producto_model.dart';

class RecomendacionesScreen extends StatefulWidget {
  final String? productoReferencia;
  final String? categoriaReferencia;

  const RecomendacionesScreen({
    super.key,
    this.productoReferencia,
    this.categoriaReferencia,
  });

  @override
  State<RecomendacionesScreen> createState() => _RecomendacionesScreenState();
}

class _RecomendacionesScreenState extends State<RecomendacionesScreen> {
  final RecomendacionService _recomendacionService = RecomendacionService();
  List<Producto> _productosRecomendados = [];
  bool _cargando = true;
  String _titulo = 'Recomendaciones';

  @override
  void initState() {
    super.initState();
    _cargarRecomendaciones();
  }

  Future<void> _cargarRecomendaciones() async {
    try {
      List<Producto> recomendaciones = [];

      if (widget.productoReferencia != null) {
        _titulo = 'Similares a "${widget.productoReferencia}"';
        recomendaciones = await _recomendacionService
            .obtenerRecomendacionesPorNombre(widget.productoReferencia!, 6);
      } else if (widget.categoriaReferencia != null) {
        _titulo = 'Más ${widget.categoriaReferencia}';
        recomendaciones = await _recomendacionService
            .obtenerRecomendacionesPorCategoria(widget.categoriaReferencia!, 6);
      } else {
        _titulo = 'Productos Populares';
        recomendaciones =
            await _recomendacionService.obtenerProductosPopulares(6);
      }

      setState(() {
        _productosRecomendados = recomendaciones;
        _cargando = false;
      });
    } catch (e) {
      print('Error cargando recomendaciones: $e');
      setState(() {
        _cargando = false;
      });
    }
  }

  String convertirEnlaceDriveADirecto(String enlaceDrive) {
    if (enlaceDrive.isEmpty) return '';

    if (enlaceDrive.contains('uc?export=view')) {
      return enlaceDrive;
    }

    final regExp1 = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final regExp2 = RegExp(r'id=([a-zA-Z0-9_-]+)');
    final regExp3 = RegExp(r'file/d/([a-zA-Z0-9_-]+)');

    String? id;

    final match1 = regExp1.firstMatch(enlaceDrive);
    final match2 = regExp2.firstMatch(enlaceDrive);
    final match3 = regExp3.firstMatch(enlaceDrive);

    if (match1 != null) {
      id = match1.group(1);
    } else if (match2 != null) {
      id = match2.group(1);
    } else if (match3 != null) {
      id = match3.group(1);
    }

    if (id != null) {
      return 'https://drive.google.com/uc?export=view&id=$id';
    } else {
      return enlaceDrive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulo),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? _buildLoadingState()
          : _productosRecomendados.isEmpty
              ? _buildEmptyState()
              : _buildProductosGrid(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Buscando recomendaciones...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No hay recomendaciones disponibles',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba con otros productos o categorías',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductosGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.70, // AJUSTADO para mejor proporción
      ),
      itemCount: _productosRecomendados.length,
      itemBuilder: (context, index) {
        final producto = _productosRecomendados[index];
        return _buildProductoCard(producto);
      },
    );
  }

  Widget _buildProductoCard(Producto producto) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _mostrarOpcionesProducto(producto);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen del producto - ALTURA FIJA
            Container(
              height: 110, // ALTURA FIJA para evitar overflow
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: Colors.grey.shade100,
              ),
              child: producto.imagen.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        convertirEnlaceDriveADirecto(producto.imagen),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bakery_dining,
                                    size: 35, color: Colors.brown.shade300),
                                const SizedBox(height: 4),
                                Text(
                                  'Sin imagen',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bakery_dining,
                              size: 35, color: Colors.brown.shade300),
                          const SizedBox(height: 4),
                          Text(
                            'Sin imagen',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Información del producto - CONTENIDO CON ESPACIO CONTROLADO
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Sección superior: Nombre y precio
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'S/ ${producto.precio.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        // Sección media: Categoría y descripción (SOLO SI HAY ESPACIO)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (producto.categoria.isNotEmpty &&
                                producto.categoria != 'General')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  producto.categoria,
                                  style: TextStyle(
                                    color: Colors.brown.shade600,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (producto.descripcion.isNotEmpty &&
                                constraints.maxHeight > 60)
                              Text(
                                producto.descripcion,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                  height: 1.2,
                                ),
                                maxLines: constraints.maxHeight > 70 ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),

                        // Botón de acción - SIEMPRE EN LA PARTE INFERIOR
                        Container(
                          width: double.infinity,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.brown.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.brown.shade200),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _agregarAlCarrito(producto),
                              borderRadius: BorderRadius.circular(6),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_shopping_cart,
                                        size: 14, color: Colors.brown.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Agregar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.brown.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarOpcionesProducto(Producto producto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              producto.nombre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'S/ ${producto.precio.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _agregarAlCarrito(producto);
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Agregar al Carrito'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _agregarAlCarrito(Producto producto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${producto.nombre} agregado al carrito'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
