import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'historial_pedidos_screen.dart';
import 'ubicacion_screen.dart';
import 'favoritos_screen.dart';
import 'sensores_screen.dart';

class PerfilClienteScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favoritos;
  final String? nombreUsuario;
  final String? emailUsuario;
  
  const PerfilClienteScreen({
    super.key, 
    required this.favoritos,
    this.nombreUsuario,
    this.emailUsuario,
  });

  @override
  State<PerfilClienteScreen> createState() => _PerfilClienteScreenState();
}

class _PerfilClienteScreenState extends State<PerfilClienteScreen> {
  File? _fotoPerfil;
  String? _fotoUrl;
  final ImagePicker _picker = ImagePicker();
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarFotoUsuario();
  }

  Future<void> _cargarFotoUsuario() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data['fotoUrl'] != null) {
            setState(() {
              _fotoUrl = data['fotoUrl'];
            });
          }
        }
      } catch (e) {
        print('Error cargando foto: $e');
      }
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      
      if (foto != null) {
        await _subirFotoAFirebase(File(foto.path));
      }
    } catch (e) {
      _mostrarError('Error al tomar foto: $e');
    }
  }

  Future<void> _seleccionarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      
      if (foto != null) {
        await _subirFotoAFirebase(File(foto.path));
      }
    } catch (e) {
      _mostrarError('Error al seleccionar foto: $e');
    }
  }

  Future<void> _subirFotoAFirebase(File imagen) async {
    setState(() {
      _cargando = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String nombreArchivo = 'perfil_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = FirebaseStorage.instance.ref().child('perfiles_usuarios/$nombreArchivo');
        
        await ref.putFile(imagen);
        
        String urlDescarga = await ref.getDownloadURL();
        
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({
              'fotoUrl': urlDescarga,
              'nombre': widget.nombreUsuario,
              'email': widget.emailUsuario,
              'ultimaActualizacion': DateTime.now(),
            }, SetOptions(merge: true));

        setState(() {
          _fotoUrl = urlDescarga;
          _fotoPerfil = imagen;
          _cargando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _cargando = false;
      });
      _mostrarError('Error al guardar foto: $e');
    }
  }

  Future<void> _eliminarFoto() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && _fotoUrl != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .update({'fotoUrl': FieldValue.delete()});

        setState(() {
          _fotoUrl = null;
          _fotoPerfil = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al eliminar foto: $e');
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _tomarFoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarFoto();
              },
            ),
            if (_fotoUrl != null || _fotoPerfil != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _eliminarFoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _cerrarSesion(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/', 
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildHeader(),
          _buildMenuOption(
            icon: Icons.history,
            title: 'Historial de Pedidos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistorialPedidosScreen(carrito: []),
                ),
              );
            },
          ),
          _buildMenuOption(
            icon: Icons.location_on,
            title: 'Nuestra Ubicación',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UbicacionScreen(),
                ),
              );
            },
          ),
          _buildMenuOption(
            icon: Icons.favorite,
            title: 'Mis Favoritos',
            badgeCount: widget.favoritos.length,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritosScreen(favoritos: widget.favoritos),
                ),
              );
            },
          ),
          _buildMenuOption(
            icon: Icons.sensors,
            title: 'Sensores del Móvil',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SensoresScreen()
                ),
              );
            },
          ),
          _buildMenuOption(
            icon: Icons.support,
            title: 'Soporte',
            onTap: () {
              _mostrarMensajeProximamente(context);
            },
          ),
          _buildMenuOption(
            icon: Icons.settings,
            title: 'Configuración',
            onTap: () {
              _mostrarMensajeProximamente(context);
            },
          ),
          _buildMenuOption(
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            onTap: () {
              _mostrarDialogoCerrarSesion(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final nombre = widget.nombreUsuario ?? 'Usuario MINIMARKET';
    final email = widget.emailUsuario ?? 'No especificado';

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.brown.shade50,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.brown.shade300,
                    width: 3,
                  ),
                ),
                child: _cargando 
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                        ),
                      )
                    : ClipOval(
                        child: _fotoPerfil != null
                            ? Image.file(
                                _fotoPerfil!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              )
                            : _fotoUrl != null
                                ? Image.network(
                                    _fotoUrl!,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildAvatarInicial(nombre);
                                    },
                                  )
                                : _buildAvatarInicial(nombre),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _cargando ? null : _mostrarOpcionesFoto,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _cargando ? Colors.grey : Colors.brown.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInicial(String nombre) {
    return Container(
      color: Colors.brown,
      child: Center(
        child: Text(
          nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.brown.shade700),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeCount != null && badgeCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _mostrarDialogoCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cerrarSesion(context);
            },
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _mostrarMensajeProximamente(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Próximamente disponible!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }
}