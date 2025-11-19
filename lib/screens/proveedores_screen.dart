import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final List<Proveedor> _proveedores = [
    Proveedor(
      id: '1',
      nombre: 'Distribuidora Lácteos S.A.',
      contacto: 'María González',
      telefono: '+57 300 123 4567',
      email: 'ventas@lacteosdistribuidora.com',
      producto: 'Leche, Quesos, Mantequilla',
      rating: 4.8,
      imagen: '🥛',
      color: Colors.blue.shade50,
    ),
    Proveedor(
      id: '2',
      nombre: 'Harinas Premium Ltda.',
      contacto: 'Carlos Rodríguez',
      telefono: '+57 301 234 5678',
      email: 'carlos@harinaspremium.com',
      producto: 'Harina de Trigo, Levadura',
      rating: 4.9,
      imagen: '🌾',
      color: Colors.orange.shade50,
    ),
    Proveedor(
      id: '3',
      nombre: 'Frutas y Verduras Frescas',
      contacto: 'Ana Martínez',
      telefono: '+57 302 345 6789',
      email: 'ana@frutasfrescas.com',
      producto: 'Frutas, Verduras, Huevos',
      rating: 4.7,
      imagen: '🍎',
      color: Colors.green.shade50,
    ),
    Proveedor(
      id: '4',
      nombre: 'Dulces y Azúcares S.A.',
      contacto: 'Roberto Sánchez',
      telefono: '+57 303 456 7890',
      email: 'rsanchez@dulcesazucar.com',
      producto: 'Azúcar, Chocolate, Esencias',
      rating: 4.6,
      imagen: '🍫',
      color: Colors.pink.shade50,
    ),
    Proveedor(
      id: '5',
      nombre: 'Carnes Selectas',
      contacto: 'Laura Díaz',
      telefono: '+57 304 567 8901',
      email: 'laura@carnesselectas.com',
      producto: 'Carne de Res, Pollo, Cerdo',
      rating: 4.5,
      imagen: '🥩',
      color: Colors.red.shade50,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Proveedor> _proveedoresFiltrados = [];

  @override
  void initState() {
    super.initState();
    _proveedoresFiltrados = _proveedores;
    _searchController.addListener(_filtrarProveedores);
  }

  void _filtrarProveedores() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _proveedoresFiltrados = _proveedores.where((proveedor) {
        return proveedor.nombre.toLowerCase().contains(query) ||
            proveedor.producto.toLowerCase().contains(query) ||
            proveedor.contacto.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _llamarProveedor(String telefono) async {
    final url = Uri.parse('tel:$telefono');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _mostrarSnackBar('No se puede realizar la llamada');
    }
  }

  Future<void> _enviarEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _mostrarSnackBar('No se puede abrir la aplicación de email');
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _mostrarDetallesProveedor(Proveedor proveedor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetallesProveedor(proveedor),
    );
  }

  Widget _buildDetallesProveedor(Proveedor proveedor) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: proveedor.color,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      proveedor.imagen,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proveedor.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        proveedor.producto,
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
            const SizedBox(height: 24),
            
            // Información de contacto
            _buildInfoItem(Icons.person, 'Contacto', proveedor.contacto),
            _buildInfoItem(Icons.phone, 'Teléfono', proveedor.telefono),
            _buildInfoItem(Icons.email, 'Email', proveedor.email),
            
            const SizedBox(height: 24),
            
            // Rating
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${proveedor.rating}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '/5.0',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _llamarProveedor(proveedor.telefono),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Llamar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.brown,
                      side: const BorderSide(color: Colors.brown),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _enviarEmail(proveedor.email),
                    icon: const Icon(Icons.email, size: 18),
                    label: const Text('Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.brown),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProveedorCard(Proveedor proveedor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _mostrarDetallesProveedor(proveedor),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar/Icono
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: proveedor.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    proveedor.imagen,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proveedor.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proveedor.producto,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          proveedor.contacto,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Rating y acciones
              Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        proveedor.rating.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _llamarProveedor(proveedor.telefono),
                        icon: Icon(Icons.phone, size: 18, color: Colors.green.shade600),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _enviarEmail(proveedor.email),
                        icon: Icon(Icons.email, size: 18, color: Colors.blue.shade600),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar proveedores...',
                prefixIcon: const Icon(Icons.search, color: Colors.brown),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          
          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_proveedoresFiltrados.length} proveedores encontrados',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Lista de proveedores
          Expanded(
            child: _proveedoresFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron proveedores',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _proveedoresFiltrados.length,
                    itemBuilder: (context, index) => 
                        _buildProveedorCard(_proveedoresFiltrados[index]),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class Proveedor {
  final String id;
  final String nombre;
  final String contacto;
  final String telefono;
  final String email;
  final String producto;
  final double rating;
  final String imagen;
  final Color color;

  Proveedor({
    required this.id,
    required this.nombre,
    required this.contacto,
    required this.telefono,
    required this.email,
    required this.producto,
    required this.rating,
    required this.imagen,
    required this.color,
  });
}