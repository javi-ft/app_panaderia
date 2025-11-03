class Producto {
  final String id;
  final String nombre;
  final double precio;
  final String categoria;
  final String descripcion;
  final String imagen;
  final int stock;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.categoria,
    this.descripcion = '',
    this.imagen = '',
    this.stock = 0,
  });

  factory Producto.fromFirestore(String id, Map<String, dynamic> data) {
    return Producto(
      id: id,
      nombre: data['nombre'] ?? '',
      precio: (data['precio'] is String) 
          ? double.tryParse(data['precio']) ?? 0.0 
          : (data['precio'] ?? 0.0).toDouble(),
      categoria: data['categoria'] ?? 'General',
      descripcion: data['descripcion'] ?? '',
      imagen: data['imagen'] ?? '',
      stock: data['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'precio': precio,
      'categoria': categoria,
      'descripcion': descripcion,
      'imagen': imagen,
      'stock': stock,
    };
  }

  Producto copyWith({
    String? id,
    String? nombre,
    double? precio,
    String? categoria,
    String? descripcion,
    String? imagen,
    int? stock,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      imagen: imagen ?? this.imagen,
      stock: stock ?? this.stock,
    );
  }
}