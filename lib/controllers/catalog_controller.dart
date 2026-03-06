import 'package:flutter/foundation.dart';
import '../models/vehicle_type_model.dart';
import '../models/washed_type_model.dart';
import '../services/vehicle_type_service.dart';
import '../services/washed_type_service.dart';

/// Estados del catálogo de servicios.
enum CatalogStatus {
  initial, // Estado inicial
  loading, // Cargando datos
  loaded, // Datos cargados
  error, // Error al cargar
}

/// Controller que gestiona el catálogo de tipos de vehículos y lavados.
/// 
/// Se encarga de:
/// - Cargar tipos de vehículos y lavados
/// - Crear y actualizar tipos (solo administradores)
/// - Filtrar tipos de lavado por vehículo
class CatalogController extends ChangeNotifier {
  final VehicleTypeService _vehicleTypeService = VehicleTypeService();
  final WashedTypeService _washedTypeService = WashedTypeService();

  CatalogStatus _status = CatalogStatus.initial;
  List<VehicleTypeModel> _vehicleTypes = [];
  List<WashedTypeModel> _washedTypes = [];
  String? _errorMessage;

  /// Estado actual del catálogo.
  CatalogStatus get status => _status;

  /// Lista de tipos de vehículos.
  List<VehicleTypeModel> get vehicleTypes => _vehicleTypes;

  /// Lista de tipos de lavado.
  List<WashedTypeModel> get washedTypes => _washedTypes;

  /// Mensaje de error de la última operación.
  String? get errorMessage => _errorMessage;

  /// Indica si hay una operación en progreso.
  bool get isLoading => _status == CatalogStatus.loading;

  /// Carga todos los tipos de vehículos y lavados.
  Future<bool> loadCatalog() async {
    try {
      _status = CatalogStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _vehicleTypes = await _vehicleTypeService.getAllVehicleTypes();
      _washedTypes = await _washedTypeService.getAllWashedTypes();

      _status = CatalogStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = CatalogStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Obtiene tipos de lavado filtrados por tipo de vehículo.
  List<WashedTypeModel> getWashedTypesByVehicle(int vehicleTypeId) {
    return _washedTypes
        .where((wt) => wt.vehicleTypeId == vehicleTypeId)
        .toList();
  }

  /// Crea un nuevo tipo de vehículo (solo para administradores).
  Future<VehicleTypeModel?> createVehicleType(String name) async {
    try {
      _errorMessage = null;

      final vehicleType = await _vehicleTypeService.createVehicleType(name);
      _vehicleTypes.add(vehicleType);
      _vehicleTypes.sort((a, b) => a.name.compareTo(b.name));

      notifyListeners();
      return vehicleType;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Actualiza un tipo de vehículo (solo para administradores).
  Future<VehicleTypeModel?> updateVehicleType(int id, String name) async {
    try {
      _errorMessage = null;

      final updatedType = await _vehicleTypeService.updateVehicleType(id, name);
      
      final index = _vehicleTypes.indexWhere((vt) => vt.id == id);
      if (index != -1) {
        _vehicleTypes[index] = updatedType;
        _vehicleTypes.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }

      return updatedType;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Crea un nuevo tipo de lavado (solo para administradores).
  Future<WashedTypeModel?> createWashedType({
    required String name,
    required int vehicleTypeId,
    required double price,
  }) async {
    try {
      _errorMessage = null;

      final washedType = await _washedTypeService.createWashedType(
        name: name,
        vehicleTypeId: vehicleTypeId,
        price: price,
      );

      _washedTypes.add(washedType);
      _washedTypes.sort((a, b) => a.name.compareTo(b.name));

      notifyListeners();
      return washedType;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Actualiza un tipo de lavado (solo para administradores).
  Future<WashedTypeModel?> updateWashedType({
    required int id,
    String? name,
    int? vehicleTypeId,
    double? price,
  }) async {
    try {
      _errorMessage = null;

      final updatedType = await _washedTypeService.updateWashedType(
        id: id,
        name: name,
        vehicleTypeId: vehicleTypeId,
        price: price,
      );

      final index = _washedTypes.indexWhere((wt) => wt.id == id);
      if (index != -1) {
        _washedTypes[index] = updatedType;
        _washedTypes.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }

      return updatedType;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Recarga el catálogo completo.
  Future<void> refresh() async {
    await loadCatalog();
  }
}
