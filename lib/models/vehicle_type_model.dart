/// Modelo de tipo de vehículo que corresponde a la tabla 'vehicle_type' en Supabase.
/// 
/// Representa los diferentes tipos de vehículos disponibles para el lavado.
class VehicleTypeModel {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleTypeModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crea un VehicleTypeModel desde un Map (típicamente de Supabase).
  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convierte el VehicleTypeModel a un Map para enviar a Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crea una copia del VehicleTypeModel con los campos actualizados.
  VehicleTypeModel copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
