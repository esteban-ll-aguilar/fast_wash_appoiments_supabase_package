/// Modelo de cita que corresponde a la tabla 'appointment' en Supabase.
/// 
/// Representa una cita de lavado agendada por un usuario.
class AppointmentModel {
  final int id;
  final String userDni;
  final int washedTypeId;
  final AppointmentStatus status;
  final DateTime appointmentDate;
  final String appointmentTime; // Formato HH:mm
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos opcionales para información relacionada
  final String? userName;
  final String? washedTypeName;
  final double? washedTypePrice;
  final String? vehicleTypeName;

  AppointmentModel({
    required this.id,
    required this.userDni,
    required this.washedTypeId,
    required this.status,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.washedTypeName,
    this.washedTypePrice,
    this.vehicleTypeName,
  });

  /// Crea un AppointmentModel desde un Map (típicamente de Supabase).
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int,
      userDni: json['user_dni'] as String,
      washedTypeId: json['washed_type_id'] as int,
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status'] as String).toUpperCase(),
        orElse: () => AppointmentStatus.UNPAYMENT,
      ),
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      appointmentTime: json['appointment_time'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // Campos relacionados (si se hizo JOIN)
      userName: json['user']?['first_name'] != null && json['user']?['last_name'] != null
          ? '${json['user']['first_name']} ${json['user']['last_name']}'
          : null,
      washedTypeName: json['washed_type']?['name'] as String?,
      washedTypePrice: json['washed_type']?['price'] != null
          ? (json['washed_type']['price'] as num).toDouble()
          : null,
      vehicleTypeName: json['washed_type']?['vehicle_type']?['name'] as String?,
    );
  }

  /// Convierte el AppointmentModel a un Map para enviar a Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_dni': userDni,
      'washed_type_id': washedTypeId,
      'status': status.name.toUpperCase(),
      'appointment_date': appointmentDate.toIso8601String().split('T')[0],
      'appointment_time': appointmentTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Retorna la fecha y hora completas de la cita.
  DateTime get fullDateTime {
    final timeParts = appointmentTime.split(':');
    return DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  /// Verifica si la cita está pagada.
  bool get isPaid => status == AppointmentStatus.PAYMENT;

  /// Formato de fecha legible.
  String get formattedDate {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${appointmentDate.day} de ${months[appointmentDate.month - 1]} ${appointmentDate.year}';
  }

  /// Formato de precio si está disponible.
  String? get formattedPrice =>
      washedTypePrice != null ? '\$${washedTypePrice!.toStringAsFixed(2)}' : null;

  /// Crea una copia del AppointmentModel con los campos actualizados.
  AppointmentModel copyWith({
    int? id,
    String? userDni,
    int? washedTypeId,
    AppointmentStatus? status,
    DateTime? appointmentDate,
    String? appointmentTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? washedTypeName,
    double? washedTypePrice,
    String? vehicleTypeName,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userDni: userDni ?? this.userDni,
      washedTypeId: washedTypeId ?? this.washedTypeId,
      status: status ?? this.status,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      washedTypeName: washedTypeName ?? this.washedTypeName,
      washedTypePrice: washedTypePrice ?? this.washedTypePrice,
      vehicleTypeName: vehicleTypeName ?? this.vehicleTypeName,
    );
  }
}

/// Estados de pago de una cita.
enum AppointmentStatus {
  PAYMENT,
  UNPAYMENT,
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get displayName {
    switch (this) {
      case AppointmentStatus.PAYMENT:
        return 'Pagado';
      case AppointmentStatus.UNPAYMENT:
        return 'Pendiente de Pago';
    }
  }
}
