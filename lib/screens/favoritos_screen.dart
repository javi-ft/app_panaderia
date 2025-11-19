import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavoritosScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favoritos;

  const FavoritosScreen({super.key, required this.favoritos});

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

  Widget _buildPlaceholderImagen() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.brown.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.broken_image, color: Colors.brown, size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: favoritos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes favoritos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega productos a favoritos tocando el corazón',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoritos.length,
              itemBuilder: (context, index) {
                final producto = favoritos[index];
                final urlImagenOriginal = producto['imagen'] ?? '';
                final urlImagenDirecta = convertirEnlaceDriveADirecto(urlImagenOriginal);
                final precio = double.tryParse(producto['precio'].toString()) ?? 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Imagen del producto
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: urlImagenOriginal.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: urlImagenDirecta,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    progressIndicatorBuilder: (context, url, progress) => _buildPlaceholderImagen(),
                                    errorWidget: (context, url, error) => _buildPlaceholderImagen(),
                                  )
                                : _buildPlaceholderImagen(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Información del producto
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                producto['descripcion'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'S/ ${precio.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Icono de favorito (siempre lleno en esta pantalla)
                        Icon(
                          Icons.favorite,
                          color: Colors.pink,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}