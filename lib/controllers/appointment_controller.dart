import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

/// Estados del listado de citas.
enum AppointmentListStatus {
  initial, // Estado inicial
  loading, // Cargando citas
  loaded, // Citas cargadas
  empty, // Sin citas
  error, // Error al cargar
}

/// Controller que gestiona el listado y operaciones de citas.
/// 
/// Se encarga de:
/// - Cargar citas del usuario o todas (según rol)
/// - Crear nuevas citas
/// - Actualizar citas existentes
/// - Filtrar citas por estado o fecha
class AppointmentController extends ChangeNotifier {
  final AppointmentService _appointmentService = AppointmentService();

  AppointmentListStatus _status = AppointmentListStatus.initial;
  List<AppointmentModel> _appointments = [];
  String? _errorMessage;

  /// Estado actual del listado.
  AppointmentListStatus get status => _status;

  /// Lista de citas cargadas.
  List<AppointmentModel> get appointments => _appointments;

  /// Mensaje de error de la última operación.
  String? get errorMessage => _errorMessage;

  /// Indica si hay una operación en progreso.
  bool get isLoading => _status == AppointmentListStatus.loading;

  /// Indica si la lista está vacía.
  bool get isEmpty => _appointments.isEmpty && _status == AppointmentListStatus.empty;

  /// Carga las citas del usuario actual.
  /// 
  /// Retorna true si se cargaron exitosamente, false en caso contrario.
  Future<bool> loadUserAppointments() async {
    try {
      _status = AppointmentListStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _appointments = await _appointmentService.getCurrentUserAppointments();

      if (_appointments.isEmpty) {
        _status = AppointmentListStatus.empty;
      } else {
        _status = AppointmentListStatus.loaded;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _status = AppointmentListStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Carga todas las citas (solo para administradores).
  Future<bool> loadAllAppointments() async {
    try {
      _status = AppointmentListStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _appointments = await _appointmentService.getAllAppointments();

      if (_appointments.isEmpty) {
        _status = AppointmentListStatus.empty;
      } else {
        _status = AppointmentListStatus.loaded;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _status = AppointmentListStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Crea una nueva cita.
  /// 
  /// Retorna la cita creada si es exitoso, null en caso contrario.
  Future<AppointmentModel?> createAppointment({
    required int washedTypeId,
    required DateTime appointmentDate,
    required String appointmentTime,
  }) async {
    try {
      _errorMessage = null;

      final appointment = await _appointmentService.createAppointment(
        washedTypeId: washedTypeId,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
      );

      // Agregar la nueva cita a la lista
      _appointments.insert(0, appointment);
      _status = AppointmentListStatus.loaded;
      notifyListeners();

      return appointment;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Actualiza una cita existente (solo para administradores).
  /// 
  /// Retorna la cita actualizada si es exitoso, null en caso contrario.
  Future<AppointmentModel?> updateAppointment({
    required int id,
    int? washedTypeId,
    DateTime? appointmentDate,
    String? appointmentTime,
    AppointmentStatus? status,
  }) async {
    try {
      _errorMessage = null;

      final updatedAppointment = await _appointmentService.updateAppointment(
        id: id,
        washedTypeId: washedTypeId,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        status: status,
      );

      // Actualizar la cita en la lista
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = updatedAppointment;
        notifyListeners();
      }

      return updatedAppointment;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Filtra citas por estado de pago.
  Future<bool> filterByStatus(AppointmentStatus status) async {
    try {
      _status = AppointmentListStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _appointments = await _appointmentService.getAppointmentsByStatus(status);

      if (_appointments.isEmpty) {
        _status = AppointmentListStatus.empty;
      } else {
        _status = AppointmentListStatus.loaded;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _status = AppointmentListStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Filtra citas por rango de fechas.
  Future<bool> filterByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _status = AppointmentListStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _appointments = await _appointmentService.getAppointmentsByDateRange(
        startDate: startDate,
        endDate: endDate,
      );

      if (_appointments.isEmpty) {
        _status = AppointmentListStatus.empty;
      } else {
        _status = AppointmentListStatus.loaded;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _status = AppointmentListStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Verifica si un horario está disponible.
  Future<bool> isTimeSlotAvailable({
    required DateTime date,
    required String time,
    int? excludeAppointmentId,
  }) async {
    try {
      return await _appointmentService.isTimeSlotAvailable(
        date: date,
        time: time,
        excludeAppointmentId: excludeAppointmentId,
      );
    } catch (e) {
      return false;
    }
  }

  /// Recarga las citas.
  Future<void> refresh() async {
    await loadUserAppointments();
  }
}
