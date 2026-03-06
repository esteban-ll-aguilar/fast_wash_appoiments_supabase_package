import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment_model.dart';

/// Servicio para gestionar operaciones relacionadas con citas en Supabase.
class AppointmentService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todas las citas del usuario actual.
  /// 
  /// Incluye información relacionada del tipo de lavado y vehículo.
  Future<List<AppointmentModel>> getCurrentUserAppointments() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Primero obtenemos el DNI del usuario actual
      final userResponse = await _client
          .from('users')
          .select('dni')
          .eq('id', user.id)
          .single();

      final userDni = userResponse['dni'] as String?;
      if (userDni == null) {
        throw Exception('Usuario no tiene DNI registrado');
      }

      final response = await _client
          .from('appointment')
          .select('''
            *,
            user:users!appointment_user_dni_fkey(first_name, last_name),
            washed_type(
              name,
              price,
              vehicle_type(name)
            )
          ''')
          .eq('user_dni', userDni)
          .order('appointment_date', ascending: false)
          .order('appointment_time', ascending: false);

      return (response as List)
          .map((json) => AppointmentModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene todas las citas (solo para administradores).
  Future<List<AppointmentModel>> getAllAppointments() async {
    try {
      final response = await _client
          .from('appointment')
          .select('''
            *,
            user:users!appointment_user_dni_fkey(first_name, last_name),
            washed_type(
              name,
              price,
              vehicle_type(name)
            )
          ''')
          .order('appointment_date', ascending: false)
          .order('appointment_time', ascending: false);

      return (response as List)
          .map((json) => AppointmentModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene una cita por su ID.
  Future<AppointmentModel?> getAppointmentById(int id) async {
    try {
      final response = await _client
          .from('appointment')
          .select('''
            *,
            user:users!appointment_user_dni_fkey(first_name, last_name),
            washed_type(
              name,
              price,
              vehicle_type(name)
            )
          ''')
          .eq('id', id)
          .single();

      return AppointmentModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Crea una nueva cita.
  /// 
  /// El DNI del usuario se obtiene automáticamente del usuario actual.
  /// Retorna [AppointmentModel] creado si es exitoso.
  Future<AppointmentModel> createAppointment({
    required int washedTypeId,
    required DateTime appointmentDate,
    required String appointmentTime,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Obtener el DNI del usuario actual
      final userResponse = await _client
          .from('users')
          .select('dni')
          .eq('id', user.id)
          .single();

      final userDni = userResponse['dni'] as String?;
      if (userDni == null) {
        throw Exception('Debe completar su perfil antes de crear una cita');
      }

      final response = await _client
          .from('appointment')
          .insert({
            'user_dni': userDni,
            'washed_type_id': washedTypeId,
            'appointment_date': appointmentDate.toIso8601String().split('T')[0],
            'appointment_time': appointmentTime,
            'status': 'UNPAYMENT',
          })
          .select('''
            *,
            user:users!appointment_user_dni_fkey(first_name, last_name),
            washed_type(
              name,
              price,
              vehicle_type(name)
            )
          ''')
          .single();

      return AppointmentModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza una cita existente (solo para administradores).
  /// 
  /// Permite actualizar el tipo de lavado, fecha, hora y estado de pago.
  Future<AppointmentModel> updateAppointment({
    required int id,
    int? washedTypeId,
    DateTime? appointmentDate,
    String? appointmentTime,
    AppointmentStatus? status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (washedTypeId != null) updateData['washed_type_id'] = washedTypeId;
      if (appointmentDate != null) {
        updateData['appointment_date'] = appointmentDate.toIso8601String().split('T')[0];
      }
      if (appointmentTime != null) updateData['appointment_time'] = appointmentTime;
      if (status != null) updateData['status'] = status.name.toUpperCase();

      final response = await _client
          .from('appointment')
          .update(updateData)
          .eq('id', id)
          .select('''
            *,
            user:users!appointment_user_dni_fkey(first_name, last_name),
            washed_type(
              name,
              price,
              vehicle_type(name)
            )
          ''')
          .single();

      return AppointmentModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Filtra citas por rango de fechas.
  Future<List<AppointmentModel>> getAppointmentsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client
          .from('appointment')
          .select('''
            *,
            user:users!appointment_user_dni_fkey(first_name, last_name),
            washed_type(
              name,
              price,
              vehicle_type(name)
            )
          ''')
          .gte('appointment_date', startDate.toIso8601String().split('T')[0])
          .lte('appointment_date', endDate.toIso8601String().split('T')[0])
          .order('appointment_date', ascending: true)
          .order('appointment_time', ascending: true);

      return (response as List)
          .map((json) => AppointmentModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Filtra citas por estado de pago.
  Future<List<AppointmentModel>> getAppointmentsByStatus(AppointmentStatus status) async {
    try {
      final response = await _client
          .from('appointment')
          .select('''
            *,
            user:users!appointment_user_dni_fkey(first_name, last_name),
            washed_type(
              name,
              price,
              vehicle_type(name)
            )
          ''')
          .eq('status', status.name.toUpperCase())
          .order('appointment_date', ascending: false)
          .order('appointment_time', ascending: false);

      return (response as List)
          .map((json) => AppointmentModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica si ya existe una cita en la misma fecha y hora.
  Future<bool> isTimeSlotAvailable({
    required DateTime date,
    required String time,
    int? excludeAppointmentId,
  }) async {
    try {
      var query = _client
          .from('appointment')
          .select('id')
          .eq('appointment_date', date.toIso8601String().split('T')[0])
          .eq('appointment_time', time);

      if (excludeAppointmentId != null) {
        query = query.neq('id', excludeAppointmentId);
      }

      final response = await query.maybeSingle();
      return response == null; // Si no hay respuesta, el horario está disponible
    } catch (e) {
      return false;
    }
  }
}
