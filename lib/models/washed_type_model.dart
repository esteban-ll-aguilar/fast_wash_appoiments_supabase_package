/// Modelo de tipo de lavado que corresponde a la tabla 'washed_type' en Supabase.
/// 
/// Representa los diferentes tipos de lavado disponibles con su precio.
class WashedTypeModel {
  final int id;
  final String name;
  final int vehicleTypeId;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campo opcional para información relacionada del vehículo
  final String? vehicleTypeName;

  WashedTypeModel({
    required this.id,
    required this.name,
    required this.vehicleTypeId,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    this.vehicleTypeName,
  });

  /// Crea un WashedTypeModel desde un Map (típicamente de Supabase).
  factory WashedTypeModel.fromJson(Map<String, dynamic> json) {
    return WashedTypeModel(
      id: json['id'] as int,
      name: json['name'] as String,
      vehicleTypeId: json['vehicle_type_id'] as int,
      price: (json['price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      vehicleTypeName: json['vehicle_type']?['name'] as String?,
    );
  }

  /// Convierte el WashedTypeModel a un Map para enviar a Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vehicle_type_id': vehicleTypeId,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Formato del precio con símbolo de moneda.
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  /// Crea una copia del WashedTypeModel con los campos actualizados.
  WashedTypeModel copyWith({
    int? id,
    String? name,
    int? vehicleTypeId,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? vehicleTypeName,
  }) {
    return WashedTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      vehicleTypeName: vehicleTypeName ?? this.vehicleTypeName,
    );
  }
}
