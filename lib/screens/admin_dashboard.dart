import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  // Lista de pantallas/screens
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductosScreen(),
    const PedidosScreen(),
    const UsuariosScreen(),
    const ReportesScreen(),
  ];

  // Títulos para el AppBar
  final List<String> _screenTitles = [
    'Dashboard Principal',
    'Gestión de Productos',
    'Gestión de Pedidos',
    'Gestión de Usuarios',
    'Reportes y Estadísticas'
  ];

  // Íconos para la barra de navegación
  final List<IconData> _navIcons = [
    Icons.dashboard,
    Icons.shopping_bag,
    Icons.list_alt,
    Icons.people,
    Icons.analytics,
  ];

  // Etiquetas para la barra de navegación
  final List<String> _navLabels = [
    'Dashboard',
    'Productos',
    'Pedidos',
    'Usuarios',
    'Reportes'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_navIcons[_currentIndex]),
            const SizedBox(width: 12),
            Text(_screenTitles[_currentIndex]),
          ],
        ),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              _mostrarMensaje(context, 'Notificaciones');
            },
            tooltip: 'Notificaciones',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _mostrarConfirmacionCerrarSesion(context);
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text(
              "Administrador MINIMARKET",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text("admin@flori.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                "A",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.indigo.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.indigo.shade700,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _navLabels.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(
                    _navIcons[index],
                    color: _currentIndex == index 
                        ? Colors.indigo.shade700 
                        : Colors.grey.shade700,
                  ),
                  title: Text(
                    _navLabels[index],
                    style: TextStyle(
                      fontWeight: _currentIndex == index 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      color: _currentIndex == index 
                          ? Colors.indigo.shade700 
                          : Colors.grey.shade700,
                    ),
                  ),
                  selected: _currentIndex == index,
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                    Navigator.pop(context); // Cerrar el drawer
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Configuración'),
            onTap: () {
              _mostrarMensaje(context, 'Configuración');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.grey),
            title: const Text('Ayuda'),
            onTap: () {
              _mostrarMensaje(context, 'Ayuda y Soporte');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.indigo.shade700,
      unselectedItemColor: Colors.grey.shade600,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      items: [
        for (int i = 0; i < _navLabels.length; i++)
          BottomNavigationBarItem(
            icon: Icon(_navIcons[i]),
            label: _navLabels[i],
          ),
      ],
    );
  }

  void _mostrarMensaje(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarConfirmacionCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _mostrarMensaje(context, 'Sesión cerrada');
                // Aquí iría la lógica real de cierre de sesión
              },
              child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

// ========== DASHBOARD SCREEN CORREGIDO ==========
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalUsuarios = 0;

  @override
  void initState() {
    super.initState();
    _cargarTotalUsuarios();
  }

  Future<void> _cargarTotalUsuarios() async {
    try {
      // SOLUCIÓN: Contar documentos en la colección 'usuarios'
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .get();
      
      setState(() {
        _totalUsuarios = snapshot.docs.length;
      });
    } catch (e) {
      print('⚠️ No se pudo cargar usuarios: $e');
      // Si no existe la colección, mostrar 0
      setState(() {
        _totalUsuarios = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen General',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Tarjetas de estadísticas
          Row(
            children: [
              // PRODUCTOS
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('productos').snapshots(),
                  builder: (context, snapshot) {
                    final totalProducts = snapshot.data?.docs.length ?? 0;
                    return _buildStatCard(
                      'Productos', 
                      totalProducts, 
                      Icons.shopping_bag, 
                      Colors.blue,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // USUARIOS - SOLUCIÓN DIRECTA
              Expanded(
                child: _buildStatCard(
                  'Usuarios', 
                  _totalUsuarios, 
                  Icons.people, 
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              
              // PEDIDOS
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('pedidos').snapshots(),
                  builder: (context, snapshot) {
                    final totalOrders = snapshot.data?.docs.length ?? 0;
                    return _buildStatCard(
                      'Pedidos', 
                      totalOrders, 
                      Icons.list_alt, 
                      Colors.orange,
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Resto del dashboard...
          _buildAlertasRapidas(),
          
          const SizedBox(height: 30),
          
          _buildAccionesRapidas(context),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ... (los demás métodos se mantienen igual)
  Widget _buildAlertasRapidas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertas Rápidas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('pedidos').snapshots(),
                builder: (context, snapshot) {
                  final pendingOrders = snapshot.data?.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['estado'] == 'Pendiente';
                  }).length ?? 0;
                  
                  return _buildAlertCard(
                    'Pedidos Pendientes', 
                    pendingOrders, 
                    Icons.pending_actions, 
                    Colors.orange,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('productos').snapshots(),
                builder: (context, snapshot) {
                  final lowStockProducts = snapshot.data?.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final stock = data['stock'] ?? 0;
                    return stock <= 5;
                  }).length ?? 0;
                  
                  return _buildAlertCard(
                    'Stock Bajo', 
                    lowStockProducts, 
                    Icons.warning, 
                    Colors.red,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertCard(String title, int count, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: color
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: color, 
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionesRapidas(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionCard('Agregar Producto', Icons.add, Colors.blue, () {
              _navigateToScreen(context, 1);
            }),
            _buildActionCard('Ver Pedidos', Icons.shopping_cart, Colors.green, () {
              _navigateToScreen(context, 2);
            }),
            _buildActionCard('Ver Reportes', Icons.analytics, Colors.purple, () {
              _navigateToScreen(context, 4);
            }),
            _buildActionCard('Gestionar Usuarios', Icons.people, Colors.orange, () {
              _navigateToScreen(context, 3);
            }),
          ],
        ),
      ],
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    final adminState = context.findAncestorStateOfType<_AdminDashboardState>();
    if (adminState != null) {
      adminState.setState(() {
        adminState._currentIndex = index;
      });
    }
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Container(
          width: 120,
          height: 100,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ========== PRODUCTOS SCREEN CORREGIDO ==========
class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoriaController = TextEditingController();
  
  String? _editingId;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  final List<String> _categorias = [
    'gourmet',
    'panes dulces y bolleria',
    'panes tradicionales',
    'postres',
    'tortas y pasteles',
  ];

  @override
  void initState() {
    super.initState();
    // Cargar categorías si es necesario
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _mostrarSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('productos')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = ref.putFile(_selectedImage!);
      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      
      print('✅ Imagen subida correctamente: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error subiendo imagen: $e');
      _mostrarSnackBar('Error subiendo imagen: $e');
      return null;
    }
  }

  Future<void> _guardarProducto() async {
    if (_isUploading) return;
    
    // Ocultar teclado
    FocusScope.of(context).unfocus();
    
    setState(() => _isUploading = true);

    final nombre = _nombreController.text.trim();
    final precio = double.tryParse(_precioController.text) ?? 0.0;
    final descripcion = _descripcionController.text.trim();
    final stock = int.tryParse(_stockController.text) ?? 0;
    final categoria = _categoriaController.text.trim();

    // Validaciones
    if (nombre.isEmpty) {
      _mostrarSnackBar('El nombre del producto es obligatorio');
      setState(() => _isUploading = false);
      return;
    }

    if (precio <= 0) {
      _mostrarSnackBar('El precio debe ser mayor a 0');
      setState(() => _isUploading = false);
      return;
    }

    if (categoria.isEmpty) {
      _mostrarSnackBar('Por favor selecciona una categoría');
      setState(() => _isUploading = false);
      return;
    }

    try {
      print('🔄 Subiendo imagen...');
      final imageUrl = await _uploadImage();
      print('🔄 Guardando producto en Firestore...');
      
      final ref = FirebaseFirestore.instance.collection('productos');
      
      final productData = {
        'nombre': nombre,
        'precio': precio,
        'descripcion': descripcion,
        'stock': stock,
        'categoria': categoria,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'activo': true,
      };

      // Solo agregar imagenUrl si se subió correctamente
      if (imageUrl != null) {
        productData['imagenUrl'] = imageUrl;
        print('✅ Imagen agregada al producto: $imageUrl');
      }

      if (_editingId == null) {
        // NUEVO PRODUCTO
        await ref.add(productData);
        _mostrarSnackBar('✅ Producto agregado correctamente');
        print('✅ Nuevo producto guardado');
      } else {
        // EDITAR PRODUCTO
        productData['fechaActualizacion'] = FieldValue.serverTimestamp();
        await ref.doc(_editingId).update(productData);
        _mostrarSnackBar('✅ Producto actualizado correctamente');
        print('✅ Producto actualizado: $_editingId');
      }

      _limpiarFormulario();
    } catch (e) {
      print('❌ Error guardando producto: $e');
      _mostrarSnackBar('❌ Error: $e');
    }

    setState(() => _isUploading = false);
  }

  void _editarProducto(Map<String, dynamic> data, String id) {
    setState(() {
      _nombreController.text = data['nombre'] ?? '';
      _precioController.text = data['precio']?.toString() ?? '0';
      _descripcionController.text = data['descripcion'] ?? '';
      _stockController.text = data['stock']?.toString() ?? '0';
      _categoriaController.text = data['categoria'] ?? '';
      _editingId = id;
      _selectedImage = null;
    });
    
    // Scroll al formulario
    Scrollable.ensureVisible(context);
  }

  void _eliminarProducto(String id) async {
    bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres desactivar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desactivar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await FirebaseFirestore.instance.collection('productos').doc(id).update({
          'activo': false,
          'fechaEliminacion': FieldValue.serverTimestamp(),
        });
        _mostrarSnackBar('✅ Producto desactivado correctamente');
      } catch (e) {
        _mostrarSnackBar('❌ Error al eliminar: $e');
      }
    }
  }

  void _activarProducto(String id) async {
    try {
      await FirebaseFirestore.instance.collection('productos').doc(id).update({
        'activo': true,
        'fechaReactivacion': FieldValue.serverTimestamp(),
      });
      _mostrarSnackBar('✅ Producto activado correctamente');
    } catch (e) {
      _mostrarSnackBar('❌ Error al activar: $e');
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _precioController.clear();
    _descripcionController.clear();
    _stockController.clear();
    _categoriaController.clear();
    setState(() {
      _editingId = null;
      _selectedImage = null;
    });
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 3),
        backgroundColor: mensaje.contains('❌') ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildProductForm() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del formulario
            Row(
              children: [
                Icon(
                  _editingId == null ? Icons.add_circle : Icons.edit,
                  color: Colors.indigo,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  _editingId == null ? 'Agregar Nuevo Producto' : 'Editar Producto',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Sección de imagen
            _buildImageSection(),
            const SizedBox(height: 20),
            
            // Campos del formulario
            _buildFormFields(),
            const SizedBox(height: 24),
            
            // Botones de acción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagen del Producto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Toca para agregar una imagen',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '(Recomendado: 800x800 px)',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Nombre
        TextField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Producto *',
            hintText: 'Ej: Pan Francés, Torta de Chocolate',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.shopping_bag),
          ),
        ),
        const SizedBox(height: 16),
        
        // Precio y Stock
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio (S/) *',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock *',
                  hintText: '0',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Categoría
        DropdownButtonFormField<String>(
          value: _categoriaController.text.isEmpty ? null : _categoriaController.text,
          decoration: const InputDecoration(
            labelText: 'Categoría *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: _categorias.map((categoria) {
            return DropdownMenuItem(
              value: categoria,
              child: Text(categoria),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _categoriaController.text = value!;
            });
          },
          hint: const Text('Selecciona una categoría'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor selecciona una categoría';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Descripción
        TextField(
          controller: _descripcionController,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            hintText: 'Describe las características del producto...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _guardarProducto,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(_editingId == null ? Icons.add : Icons.save),
            label: Text(
              _isUploading 
                  ? 'Guardando...' 
                  : _editingId == null ? 'Agregar Producto' : 'Actualizar Producto',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (_editingId != null) ...[
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _limpiarFormulario,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.cancel),
            label: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductList() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header de la lista
            const Row(
              children: [
                Icon(Icons.list_alt, color: Colors.indigo, size: 28),
                SizedBox(width: 12),
                Text(
                  'Lista de Productos',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Lista de productos
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('productos')
                    .orderBy('fechaCreacion', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final products = snapshot.data!.docs;
                  return _buildProductsGrid(products);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<QueryDocumentSnapshot> products) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final doc = products[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildProductCard(doc.id, data);
      },
    );
  }

  Widget _buildProductCard(String id, Map<String, dynamic> data) {
    final nombre = data['nombre'] ?? 'Sin nombre';
    final precio = data['precio'] ?? 0.0;
    final descripcion = data['descripcion'] ?? '';
    final stock = data['stock'] ?? 0;
    final categoria = data['categoria'] ?? 'Sin categoría';
    final imagenUrl = data['imagenUrl'];
    final isActive = data['activo'] ?? true;
    final isLowStock = stock <= 5;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen del producto
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.grey.shade200,
                ),
                child: imagenUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          imagenUrl,
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
                            return const Center(
                              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
                      ),
              ),
              
              // Información del producto
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'S/ ${precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock: $stock',
                      style: TextStyle(
                        color: isLowStock ? Colors.red : Colors.grey.shade600,
                        fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categoria,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Badges y botones de acción
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'INACTIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isLowStock && isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'STOCK BAJO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Botones de acción
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editarProducto(data, id),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(6),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(isActive ? Icons.delete : Icons.check, size: 18),
                  onPressed: () => isActive ? _eliminarProducto(id) : _activarProducto(id),
                  style: IconButton.styleFrom(
                    backgroundColor: isActive ? Colors.red.withOpacity(0.9) : Colors.green.withOpacity(0.9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando productos...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar productos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No hay productos registrados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Comienza agregando tu primer producto',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _limpiarFormulario();
              Scrollable.ensureVisible(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar Primer Producto'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          // Vista de escritorio
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildProductForm()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildProductList()),
            ],
          );
        } else {
          // Vista móvil
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProductForm(),
                const SizedBox(height: 20),
                _buildProductList(),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    _stockController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }
}

// ========== PEDIDOS SCREEN ==========
class PedidosScreen extends StatelessWidget {
  const PedidosScreen({super.key});

  Future<void> _actualizarEstadoPedido(String pedidoId, String nuevoEstado, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('pedidos').doc(pedidoId).update({
        'estado': nuevoEstado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Pedido actualizado a: $nuevoEstado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error actualizando pedido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completado': return Colors.green;
      case 'En proceso': return Colors.orange;
      case 'En camino': return Colors.blue;
      case 'Cancelado': return Colors.red;
      default: return Colors.grey; // Pendiente
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completado': return Icons.check_circle;
      case 'En proceso': return Icons.access_time;
      case 'En camino': return Icons.delivery_dining;
      case 'Cancelado': return Icons.cancel;
      default: return Icons.pending; // Pendiente
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Fecha no disponible';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  double _calcularTotalPedido(List<dynamic>? productos) {
    if (productos == null) return 0.0;
    double total = 0.0;
    for (var producto in productos) {
      final precio = (producto['precio'] ?? 0).toDouble();
      final cantidad = (producto['cantidad'] ?? 1).toInt();
      total += precio * cantidad;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📦 Gestión de Pedidos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Administra todos los pedidos realizados por los clientes',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          
          // Filtros de estado
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('pedidos').snapshots(),
            builder: (context, snapshot) {
              final totalPedidos = snapshot.data?.docs.length ?? 0;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos', totalPedidos, Colors.blue, context, null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pendientes', _contarPorEstado(snapshot.data, 'Pendiente'), Colors.orange, context, 'Pendiente'),
                    const SizedBox(width: 8),
                    _buildFilterChip('En proceso', _contarPorEstado(snapshot.data, 'En proceso'), Colors.blue, context, 'En proceso'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completados', _contarPorEstado(snapshot.data, 'Completado'), Colors.green, context, 'Completado'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cancelados', _contarPorEstado(snapshot.data, 'Cancelado'), Colors.red, context, 'Cancelado'),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pedidos')
                  .orderBy('fechaCreacion', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando pedidos...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 50),
                        const SizedBox(height: 16),
                        Text(
                          'Error cargando pedidos: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay pedidos registrados',
                          style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Los pedidos aparecerán aquí cuando los clientes realicen compras',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final pedidos = snapshot.data!.docs;
                
                return ListView.builder(
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final doc = pedidos[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final estado = data['estado'] ?? 'Pendiente';
                    final productos = data['productos'] as List<dynamic>?;
                    final total = _calcularTotalPedido(productos);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      child: ExpansionTile(
                        leading: Icon(_getStatusIcon(estado), color: _getStatusColor(estado)),
                        title: Text(
                          'Pedido #${doc.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cliente: ${data['clienteNombre'] ?? 'Cliente no registrado'}'),
                            Text('Total: S/ ${total.toStringAsFixed(2)}'),
                            Text('Fecha: ${_formatDate(data['fechaCreacion'])}'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            estado,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: _getStatusColor(estado),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Información del cliente
                                const Text(
                                  'Información del Cliente:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.person, size: 20),
                                  title: Text('Nombre: ${data['clienteNombre'] ?? 'No especificado'}'),
                                ),
                                ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.phone, size: 20),
                                  title: Text('Teléfono: ${data['clienteTelefono'] ?? 'No especificado'}'),
                                ),
                                ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.email, size: 20),
                                  title: Text('Email: ${data['clienteEmail'] ?? 'No especificado'}'),
                                ),
                                if (data['direccion'] != null) ...[
                                  ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.location_on, size: 20),
                                    title: Text('Dirección: ${data['direccion']}'),
                                  ),
                                ],
                                
                                const SizedBox(height: 16),
                                
                                // Productos del pedido
                                const Text(
                                  'Productos del Pedido:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                ..._buildListaProductos(productos),
                                
                                const SizedBox(height: 16),
                                
                                // Resumen del pedido
                                Card(
                                  color: Colors.grey.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'TOTAL DEL PEDIDO:',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'S/ ${total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Cambiar estado del pedido
                                const Text(
                                  'Cambiar Estado del Pedido:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildEstadoButton('Pendiente', doc.id, Colors.orange, context),
                                    _buildEstadoButton('En proceso', doc.id, Colors.blue, context),
                                    _buildEstadoButton('En camino', doc.id, Colors.purple, context),
                                    _buildEstadoButton('Completado', doc.id, Colors.green, context),
                                    _buildEstadoButton('Cancelado', doc.id, Colors.red, context),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, Color color, BuildContext context, String? estado) {
    return FilterChip(
      label: Text('$label ($count)'),
      selected: false,
      onSelected: (_) {
        // Aquí puedes implementar el filtrado por estado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filtrando por: $label')),
        );
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color.withOpacity(0.3),
      labelStyle: TextStyle(color: color),
      checkmarkColor: color,
    );
  }

  int _contarPorEstado(QuerySnapshot? snapshot, String estado) {
    if (snapshot == null) return 0;
    return snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['estado'] ?? 'Pendiente') == estado;
    }).length;
  }

  List<Widget> _buildListaProductos(List<dynamic>? productos) {
    if (productos == null || productos.isEmpty) {
      return [const Text('No hay productos en este pedido')];
    }
    
    return productos.map((producto) {
      final productData = producto as Map<String, dynamic>;
      final precio = (productData['precio'] ?? 0).toDouble();
      final cantidad = (productData['cantidad'] ?? 1).toInt();
      final subtotal = precio * cantidad;
      
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          dense: true,
          leading: productData['imagenUrl'] != null
              ? Image.network(
                  productData['imagenUrl'],
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.fastfood, size: 20);
                  },
                )
              : const Icon(Icons.fastfood, size: 20),
          title: Text(productData['nombre'] ?? 'Producto sin nombre'),
          subtitle: Text('Cantidad: $cantidad - S/ $precio c/u'),
          trailing: Text(
            'S/ ${subtotal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEstadoButton(String estado, String pedidoId, Color color, BuildContext context) {
    return ElevatedButton(
      onPressed: () => _actualizarEstadoPedido(pedidoId, estado, context),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        estado,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
// ========== USUARIOS SCREEN SIMPLIFICADO ==========
class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👥 Gestión de Usuarios',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Usuarios registrados en el sistema',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          
          // Información sobre cómo configurar usuarios
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Configuración de Usuarios',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Para gestionar usuarios, necesitas:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildConfigStep('1. Crear colección "usuarios" en Firestore'),
                  _buildConfigStep('2. Sincronizar usuarios de Authentication con Firestore'),
                  _buildConfigStep('3. Implementar Cloud Functions para auto-registro'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navegar a configuración o mostrar instrucciones
                      _mostrarInstrucciones(context);
                    },
                    child: const Text('Ver Instrucciones Completas'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Usuarios actuales (si existen)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay usuarios en Firestore',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                final usuarios = snapshot.data!.docs;
                
                return ListView.builder(
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final doc = usuarios[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (data['nombre']?[0] ?? 'U').toUpperCase(),
                          ),
                        ),
                        title: Text(data['nombre'] ?? 'Sin nombre'),
                        subtitle: Text(data['email'] ?? 'Sin email'),
                        trailing: Chip(
                          label: Text(data['tipo'] ?? 'Cliente'),
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
    );
  }

  Widget _buildConfigStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _mostrarInstrucciones(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Configurar Gestión de Usuarios'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Para que funcione la gestión de usuarios:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildInstructionItem('1. Ve a Firebase Console → Firestore Database'),
                _buildInstructionItem('2. Crea una colección llamada "usuarios"'),
                _buildInstructionItem('3. Agrega documentos con esta estructura:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.shade100,
                  child: const Text(
                    '{\n'
                    '  "nombre": "Nombre del usuario",\n'
                    '  "email": "usuario@email.com",\n'
                    '  "telefono": "123456789",\n'
                    '  "tipo": "Cliente",\n'
                    '  "fechaRegistro": "timestamp",\n'
                    '  "ultimoAcceso": "timestamp"\n'
                    '}',
                    style: TextStyle(fontFamily: 'Monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text('• $text'),
    );
  }
}

// ========== REPORTES SCREEN ==========
class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Reportes y Estadísticas',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Métricas y análisis de tu negocio MINIMARKET',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          
          // Métricas principales
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pedidos')
                .where('estado', isEqualTo: 'Completado')
                .snapshots(),
            builder: (context, pedidosSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
                builder: (context, usuariosSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('productos').snapshots(),
                    builder: (context, productosSnapshot) {
                      final metricas = _calcularMetricasPrincipales(
                        pedidosSnapshot.data,
                        usuariosSnapshot.data,
                        productosSnapshot.data,
                      );
                      
                      return Column(
                        children: [
                          // Métricas principales
                          Row(
                            children: [
                              _buildMetricCard(
                                'Ventas Totales',
                                'S/ ${metricas['ventasTotales']}',
                                Icons.attach_money,
                                Colors.green,
                              ),
                              const SizedBox(width: 12),
                              _buildMetricCard(
                                'Pedidos Completados',
                                metricas['pedidosCompletados'].toString(),
                                Icons.check_circle,
                                Colors.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildMetricCard(
                                'Usuarios Registrados',
                                metricas['totalUsuarios'].toString(),
                                Icons.people,
                                Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              _buildMetricCard(
                                'Productos Activos',
                                metricas['productosActivos'].toString(),
                                Icons.shopping_bag,
                                Colors.purple,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 30),
          
          // Productos más vendidos
          const Text(
            '📈 Productos Más Vendidos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildProductosMasVendidos(),
          
          const SizedBox(height: 30),
          
          // Estadísticas de pedidos
          const Text(
            '📦 Estadísticas de Pedidos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildEstadisticasPedidos(),
          
          const SizedBox(height: 30),
          
          // Resumen mensual
          const Text(
            '🗓️ Resumen Mensual',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildResumenMensual(),
        ],
      ),
    );
  }

  Map<String, dynamic> _calcularMetricasPrincipales(
    QuerySnapshot? pedidosSnapshot,
    QuerySnapshot? usuariosSnapshot,
    QuerySnapshot? productosSnapshot,
  ) {
    double ventasTotales = 0.0;
    int pedidosCompletados = 0;
    
    if (pedidosSnapshot != null) {
      for (var doc in pedidosSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['estado'] == 'Completado') {
          pedidosCompletados++;
          final productos = data['productos'] as List<dynamic>?;
          if (productos != null) {
            for (var producto in productos) {
              final precio = (producto['precio'] ?? 0).toDouble();
              final cantidad = (producto['cantidad'] ?? 1).toInt();
              ventasTotales += precio * cantidad;
            }
          }
        }
      }
    }
    
    final totalUsuarios = usuariosSnapshot?.docs.length ?? 0;
    final productosActivos = productosSnapshot?.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['activo'] ?? true;
    }).length ?? 0;
    
    return {
      'ventasTotales': ventasTotales.toStringAsFixed(2),
      'pedidosCompletados': pedidosCompletados,
      'totalUsuarios': totalUsuarios,
      'productosActivos': productosActivos,
    };
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildProductosMasVendidos() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('pedidos')
        .where('estado', isEqualTo: 'Completado')
        .snapshots(),
    builder: (context, snapshot) {
      try {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard('No hay pedidos completados');
        }

        // CONTAR PRODUCTOS VENDIDOS
        final Map<String, int> productosVendidos = {};
        
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final productos = data['productos'];
          
          if (productos is List) {
            for (final producto in productos) {
              if (producto is Map) {
                final nombre = _obtenerNombreProducto(producto);
                final cantidad = _obtenerCantidadProducto(producto);
                productosVendidos[nombre] = (productosVendidos[nombre] ?? 0) + cantidad;
              }
            }
          }
        }

        if (productosVendidos.isEmpty) {
          return _buildEmptyCard('No hay productos vendidos');
        }

        // ORDENAR Y TOMAR TOP 5
        final productosOrdenados = productosVendidos.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        final topProductos = productosOrdenados.take(5).toList();

        return _buildProductosList(topProductos);

      } catch (e) {
        return _buildErrorCard('Error calculando productos: $e');
      }
    },
  );
}

// MÉTODOS AUXILIARES
String _obtenerNombreProducto(Map<dynamic, dynamic> producto) {
  return producto['nombre']?.toString() ?? 
         producto['productoNombre']?.toString() ?? 
         'Producto sin nombre';
}

int _obtenerCantidadProducto(Map<dynamic, dynamic> producto) {
  final cantidad = producto['cantidad'];
  if (cantidad is int) return cantidad;
  if (cantidad is double) return cantidad.toInt();
  if (cantidad is String) return int.tryParse(cantidad) ?? 1;
  return 1;
}

Widget _buildLoadingCard() {
  return const Card(
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

Widget _buildErrorCard(String mensaje) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(mensaje, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

Widget _buildEmptyCard(String mensaje) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(mensaje, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

Widget _buildProductosList(List<MapEntry<String, int>> productos) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            '🏆 Top 5 Productos Más Vendidos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...productos.asMap().entries.map((entry) {
            final index = entry.key;
            final producto = entry.value;
            final maxVentas = productos.first.value.toDouble();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Ranking
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _getRankColor(index),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Producto y barra
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: producto.value / maxVentas,
                          backgroundColor: Colors.grey.shade200,
                          color: _getRankColor(index),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Ventas
                  Text(
                    '${producto.value}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ),
  );
}

Color _getRankColor(int index) {
  switch (index) {
    case 0: return Colors.amber.shade700;
    case 1: return Colors.grey.shade500;
    case 2: return Colors.orange.shade800;
    default: return Colors.blue.shade600;
  }
}

  Widget _buildEstadisticasPedidos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pedidos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final estados = <String, int>{};
        
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final estado = data['estado'] ?? 'Pendiente';
          estados[estado] = (estados[estado] ?? 0) + 1;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Distribución de Pedidos por Estado',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ...estados.entries.map((entry) {
                  final porcentaje = snapshot.data!.docs.isNotEmpty
                      ? (entry.value / snapshot.data!.docs.length * 100).toStringAsFixed(1)
                      : '0';
                  
                  return ListTile(
                    leading: _getEstadoIcon(entry.key),
                    title: Text(entry.key),
                    trailing: Text('${entry.value} ($porcentaje%)'),
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  'Total de pedidos: ${snapshot.data!.docs.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumenMensual() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del Mes Actual',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pedidos')
                  .where('estado', isEqualTo: 'Completado')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ahora = DateTime.now();
                final inicioMes = DateTime(ahora.year, ahora.month, 1);
                double ventasMes = 0.0;
                int pedidosMes = 0;

                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fecha = (data['fechaCreacion'] as Timestamp).toDate();
                  
                  if (fecha.isAfter(inicioMes)) {
                    pedidosMes++;
                    final productos = data['productos'] as List<dynamic>?;
                    if (productos != null) {
                      for (var producto in productos) {
                        final precio = (producto['precio'] ?? 0).toDouble();
                        final cantidad = (producto['cantidad'] ?? 1).toInt();
                        ventasMes += precio * cantidad;
                      }
                    }
                  }
                }

                return Column(
                  children: [
                    _buildResumenItem('Ventas del mes', 'S/ ${ventasMes.toStringAsFixed(2)}'),
                    _buildResumenItem('Pedidos completados', pedidosMes.toString()),
                    _buildResumenItem('Ticket promedio', 
                      pedidosMes > 0 ? 'S/ ${(ventasMes / pedidosMes).toStringAsFixed(2)}' : 'S/ 0.00'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Icon _getEstadoIcon(String estado) {
    switch (estado) {
      case 'Completado': return const Icon(Icons.check_circle, color: Colors.green);
      case 'En proceso': return const Icon(Icons.access_time, color: Colors.orange);
      case 'En camino': return const Icon(Icons.delivery_dining, color: Colors.blue);
      case 'Cancelado': return const Icon(Icons.cancel, color: Colors.red);
      default: return const Icon(Icons.pending, color: Colors.grey);
    }
  }
}