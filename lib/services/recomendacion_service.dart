import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';

class RecomendacionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Producto>> obtenerRecomendacionesPorNombre(
      String nombreProducto, int limite) async {
    try {
      // 1. OBTENER CATEGORÍA DEL PRODUCTO ACTUAL
      final productoActualSnapshot = await _firestore
          .collection('productos')
          .where('nombre', isEqualTo: nombreProducto)
          .limit(1)
          .get();

      String categoriaActual = '';
      List<String> palabrasClave = [];

      if (productoActualSnapshot.docs.isNotEmpty) {
        final productoActual = productoActualSnapshot.docs.first;
        final data = productoActual.data();
        categoriaActual = data['categoria']?.toString() ?? '';
        palabrasClave = _extraerPalabrasClave(nombreProducto);
      }

      // 2. BUSCAR POR CATEGORÍA PRIMERO
      List<QueryDocumentSnapshot> productosCategoria = [];
      if (categoriaActual.isNotEmpty) {
        final queryCategoria = await _firestore
            .collection('productos')
            .where('categoria', isEqualTo: categoriaActual)
            .where('nombre', isNotEqualTo: nombreProducto)
            .limit(limite * 2)
            .get();
        productosCategoria = queryCategoria.docs;
      }

      // 3. BUSCAR POR PALABRAS CLAVE
      List<QueryDocumentSnapshot> productosPalabras = [];
      if (palabrasClave.isNotEmpty) {
        final queryPalabras = await _firestore
            .collection('productos')
            .where('nombre', isNotEqualTo: nombreProducto)
            .limit(limite * 2)
            .get();
        
        // Filtrar localmente por palabras clave
        productosPalabras = queryPalabras.docs.where((doc) {
          final nombre = (doc.data()['nombre'] ?? '').toString().toLowerCase();
          return palabrasClave.any((palabra) => nombre.contains(palabra));
        }).toList();
      }

      // 4. COMBINAR RESULTADOS
      final todosProductos = {...productosCategoria, ...productosPalabras};
      
      if (todosProductos.isEmpty) {
        return await _obtenerProductosAleatorios(limite);
      }

      // 5. ORDENAR POR RELEVANCIA
      final productosOrdenados = _ordenarPorRelevancia(
        todosProductos.toList(), 
        categoriaActual, 
        palabrasClave
      );

      return productosOrdenados.take(limite).toList();

    } catch (e) {
      print('❌ Error obteniendo recomendaciones: $e');
      return await _obtenerProductosAleatorios(limite);
    }
  }

  // MÉTODO PARA OBTENER PRODUCTOS ALEATORIOS COMO FALLBACK
  Future<List<Producto>> _obtenerProductosAleatorios(int limite) async {
    try {
      final querySnapshot = await _firestore
          .collection('productos')
          .limit(limite + 10)
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      final productos = _convertirDocsAProductos(querySnapshot.docs);
      productos.shuffle();
      return productos.take(limite).toList();
    } catch (e) {
      return [];
    }
  }

  // MÉTODO PARA RECOMENDACIONES POR CATEGORÍA (NUEVO)
  Future<List<Producto>> obtenerRecomendacionesPorCategoria(
      String categoria, int limite) async {
    try {
      final querySnapshot = await _firestore
          .collection('productos')
          .where('categoria', isEqualTo: categoria)
          .limit(limite)
          .get();

      return _convertirDocsAProductos(querySnapshot.docs);
    } catch (e) {
      print('❌ Error obteniendo recomendaciones por categoría: $e');
      return [];
    }
  }

  // MÉTODO PARA PRODUCTOS POPULARES (NUEVO)
  Future<List<Producto>> obtenerProductosPopulares(int limite) async {
    try {
      final querySnapshot = await _firestore
          .collection('productos')
          .limit(limite)
          .get();

      final productos = _convertirDocsAProductos(querySnapshot.docs);
      productos.shuffle(); // Por ahora aleatorio, luego puedes ordenar por ventas
      return productos;
    } catch (e) {
      print('❌ Error obteniendo productos populares: $e');
      return [];
    }
  }

  // EXTRAER PALABRAS CLAVE DEL NOMBRE
  List<String> _extraerPalabrasClave(String nombre) {
    final palabrasComunes = {'de', 'la', 'el', 'y', 'con', 'para', 'sin', 'al'};
    
    return nombre.toLowerCase()
        .split(RegExp(r'\s+'))
        .where((palabra) => 
            palabra.length > 2 && !palabrasComunes.contains(palabra))
        .toList();
  }

  // ORDENAR PRODUCTOS POR RELEVANCIA
  List<Producto> _ordenarPorRelevancia(
      List<QueryDocumentSnapshot> docs, 
      String categoriaActual, 
      List<String> palabrasClave) {
    
    final productos = _convertirDocsAProductos(docs);
    
    productos.sort((a, b) {
      int puntajeA = 0;
      int puntajeB = 0;

      // PUNTUAR POR CATEGORÍA
      if (a.categoria == categoriaActual) puntajeA += 3;
      if (b.categoria == categoriaActual) puntajeB += 3;

      // PUNTUAR POR PALABRAS CLAVE EN EL NOMBRE
      for (final palabra in palabrasClave) {
        if (a.nombre.toLowerCase().contains(palabra)) puntajeA += 2;
        if (b.nombre.toLowerCase().contains(palabra)) puntajeB += 2;
      }

      return puntajeB.compareTo(puntajeA);
    });

    return productos;
  }

  // CONVERTIR DOCUMENTOS A MODELO PRODUCTO
List<Producto> _convertirDocsAProductos(List<QueryDocumentSnapshot> docs) {
  return docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // VERIFICA LOS NOMBRES DE CAMPOS EN FIREBASE
    print('🎯 PRODUCTO: ${data['nombre']}');
    print('📊 CAMPOS DISPONIBLES: ${data.keys.join(', ')}');
    print('📝 Descripción: ${data['descripcion']}');
    print('🏷️ Categoría: ${data['categoria']}');
    print('💰 Precio: ${data['precio']}');
    print('🖼️ Imagen: ${data['imagen']}');
    print('---');

    return Producto(
      id: doc.id,
      nombre: data['nombre'] ?? 'Sin nombre',
      precio: double.tryParse(data['precio'].toString()) ?? 0.0,
      imagen: data['imagen'] ?? '',
      categoria: data['categoria'] ?? 'General',
      descripcion: data['descripcion'] ?? '', // ← Asegúrate que sea 'descripcion'
      stock: int.tryParse(data['stock']?.toString() ?? '0') ?? 0,
    );
  }).toList();
}
} 