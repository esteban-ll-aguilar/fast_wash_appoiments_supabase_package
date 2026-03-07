import 'document_type.dart';

/// Modelo de usuario que corresponde a la tabla 'users' en Supabase.
/// 
/// Representa un usuario del sistema con sus datos personales y rol.
class UserModel {
  final String id; // UUID del usuario en auth.users
  final String? dni; // DNI único del usuario
  final DocumentType documentType;
  final String email;
  final UserRole role;
  final String? firstName;
  final String? lastName;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.dni,
    this.documentType = DocumentType.cedula,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crea un UserModel desde un Map (típicamente de Supabase).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      dni: json['dni'] as String?,
      documentType: DocumentType.fromDb(json['document_type'] as String?),
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['role'] as String).toUpperCase(),
        orElse: () => UserRole.CLIENT,
      ),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convierte el UserModel a un Map para enviar a Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dni': dni,
      'document_type': documentType.dbValue,
      'email': email,
      'role': role.name.toUpperCase(),
      'first_name': firstName,
      'last_name': lastName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Verifica si el perfil del usuario está completo.
  /// 
  /// Un perfil se considera completo si tiene DNI, nombre y apellido.
  bool get isProfileComplete {
    return dni != null &&
        dni!.isNotEmpty &&
        firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty;
  }

  /// Retorna el nombre completo del usuario.
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return email;
  }

  /// Crea una copia del UserModel con los campos actualizados.
  UserModel copyWith({
    String? id,
    String? dni,
    DocumentType? documentType,
    String? email,
    UserRole? role,
    String? firstName,
    String? lastName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      dni: dni ?? this.dni,
      documentType: documentType ?? this.documentType,
      email: email ?? this.email,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Roles disponibles para los usuarios.
enum UserRole {
  ADMIN,
  CLIENT,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.ADMIN:
        return 'Administrador';
      case UserRole.CLIENT:
        return 'Cliente';
    }
  }
}
