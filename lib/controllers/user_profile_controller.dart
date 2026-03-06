import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

/// Estados del perfil de usuario.
enum UserProfileStatus {
  initial, // Estado inicial
  loading, // Cargando datos
  loaded, // Datos cargados
  incomplete, // Perfil incompleto (falta DNI u otros datos)
  complete, // Perfil completo
  error, // Error al cargar o actualizar
}

/// Controller que gestiona el estado del perfil de usuario.
/// 
/// Se encarga de:
/// - Cargar los datos del usuario actual
/// - Verificar si el perfil está completo
/// - Actualizar el perfil del usuario
class UserProfileController extends ChangeNotifier {
  final UserService _userService = UserService();

  UserProfileStatus _status = UserProfileStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  /// Estado actual del perfil.
  UserProfileStatus get status => _status;

  /// Usuario actual cargado.
  UserModel? get currentUser => _currentUser;

  /// Mensaje de error de la última operación.
  String? get errorMessage => _errorMessage;

  /// Indica si el perfil está completo.
  bool get isProfileComplete => 
      _currentUser != null && _currentUser!.isProfileComplete;

  /// Indica si hay una operación en progreso.
  bool get isLoading => _status == UserProfileStatus.loading;

  /// Carga los datos del usuario actual.
  /// 
  /// Retorna true si se cargó exitosamente, false en caso contrario.
  Future<bool> loadCurrentUser() async {
    try {
      _status = UserProfileStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _userService.getCurrentUser();

      if (_currentUser == null) {
        _status = UserProfileStatus.error;
        _errorMessage = 'No se pudo cargar el usuario';
        notifyListeners();
        return false;
      }

      if (_currentUser!.isProfileComplete) {
        _status = UserProfileStatus.complete;
      } else {
        _status = UserProfileStatus.incomplete;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _status = UserProfileStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Actualiza el perfil del usuario.
  /// 
  /// Retorna true si se actualizó exitosamente, false en caso contrario.
  Future<bool> updateProfile({
    String? dni,
    String? firstName,
    String? lastName,
  }) async {
    try {
      _status = UserProfileStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _userService.updateUserProfile(
        dni: dni,
        firstName: firstName,
        lastName: lastName,
      );

      if (_currentUser!.isProfileComplete) {
        _status = UserProfileStatus.complete;
      } else {
        _status = UserProfileStatus.incomplete;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _status = UserProfileStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Recarga el perfil del usuario.
  Future<void> refresh() async {
    await loadCurrentUser();
  }
}
