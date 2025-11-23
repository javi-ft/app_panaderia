import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'historial_pedidos_screen.dart';
import 'ubicacion_screen.dart';
import 'favoritos_screen.dart';
import 'sensores_screen.dart';

class PerfilClienteScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favoritos;
  final String? nombreUsuario;
  final String? emailUsuario;
  
  const PerfilClienteScreen({
    super.key, 
    required this.favoritos,
    this.nombreUsuario,
    this.emailUsuario,
  });

  void _cerrarSesion(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navegar a la pantalla inicial (login) reemplazando toda la pila de navegación
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
            badgeCount: favoritos.length,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritosScreen(favoritos: favoritos),
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
    final nombre = nombreUsuario ?? 'Usuario FLORI';
    final email = emailUsuario ?? 'No especificado';

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.brown.shade50,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.brown,
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
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
}