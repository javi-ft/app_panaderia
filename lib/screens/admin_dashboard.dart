import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _descripcionController = TextEditingController();
  String? _editingId;
  int _selectedIndex = 0;

  // Método para guardar producto
  void _guardarProducto() async {
    final nombre = _nombreController.text.trim();
    final precio = double.tryParse(_precioController.text) ?? 0.0;
    final descripcion = _descripcionController.text.trim();

    if (nombre.isEmpty || descripcion.isEmpty) {
      _mostrarSnackBar('Completa todos los campos');
      return;
    }

    try {
      final ref = FirebaseFirestore.instance.collection('productos');
      
      if (_editingId == null) {
        // Nuevo producto
        await ref.add({
          'nombre': nombre,
          'precio': precio,
          'descripcion': descripcion,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
        _mostrarSnackBar('Producto agregado correctamente');
      } else {
        // Editar producto existente
        await ref.doc(_editingId).update({
          'nombre': nombre,
          'precio': precio,
          'descripcion': descripcion,
          'fechaActualizacion': FieldValue.serverTimestamp(),
        });
        _mostrarSnackBar('Producto actualizado correctamente');
      }

      _limpiarFormulario();
    } catch (e) {
      _mostrarSnackBar('Error: $e');
    }
  }

  void _editarProducto(Map<String, dynamic> data, String id) {
    setState(() {
      _nombreController.text = data['nombre'] ?? '';
      _precioController.text = data['precio']?.toString() ?? '';
      _descripcionController.text = data['descripcion'] ?? '';
      _editingId = id;
    });
  }

  void _eliminarProducto(String id) async {
    try {
      await FirebaseFirestore.instance.collection('productos').doc(id).delete();
      _mostrarSnackBar('Producto eliminado correctamente');
    } catch (e) {
      _mostrarSnackBar('Error al eliminar: $e');
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _precioController.clear();
    _descripcionController.clear();
    setState(() {
      _editingId = null;
    });
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Widget del formulario de productos
  Widget _buildProductForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingId == null ? 'Agregar Producto' : 'Editar Producto',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _precioController,
                    decoration: const InputDecoration(
                      labelText: 'Precio (S/)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _guardarProducto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_editingId == null ? 'Agregar Producto' : 'Actualizar Producto'),
                ),
                const SizedBox(width: 16),
                if (_editingId != null)
                  ElevatedButton(
                    onPressed: _limpiarFormulario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancelar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget de la lista de productos
  Widget _buildProductList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lista de Productos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('productos')
                    .orderBy('fechaCreacion', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No hay productos registrados'),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Precio')),
                        DataColumn(label: Text('Descripción')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        
                        return DataRow(cells: [
                          DataCell(Text(data['nombre'] ?? 'Sin nombre')),
                          DataCell(Text('S/ ${data['precio']?.toStringAsFixed(2) ?? '0.00'}')),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(
                                data['descripcion'] ?? 'Sin descripción',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editarProducto(data, doc.id),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _eliminarProducto(doc.id),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      sideBar: SideBar(
        items: const [
          AdminMenuItem(
            title: 'Dashboard',
            icon: Icons.dashboard,
            route: '/dashboard',
          ),
          AdminMenuItem(
            title: 'Productos',
            icon: Icons.shopping_bag,
            route: '/productos',
          ),
          AdminMenuItem(
            title: 'Pedidos',
            icon: Icons.list_alt,
            route: '/pedidos',
          ),
          AdminMenuItem(
            title: 'Usuarios',
            icon: Icons.people,
            route: '/usuarios',
          ),
        ],
        selectedRoute: '/productos',
        onSelected: (item) {
          // Navegación entre secciones
          switch (item.route) {
            case '/dashboard':
              setState(() => _selectedIndex = 0);
              break;
            case '/productos':
              setState(() => _selectedIndex = 1);
              break;
            case '/pedidos':
              setState(() => _selectedIndex = 2);
              break;
            case '/usuarios':
              setState(() => _selectedIndex = 3);
              break;
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de Productos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 1,
              child: _buildProductForm(),
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 2,
              child: _buildProductList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}