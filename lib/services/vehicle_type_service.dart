import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_type_model.dart';

/// Servicio para gestionar operaciones relacionadas con tipos de vehículos en Supabase.
class VehicleTypeService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todos los tipos de vehículos disponibles.
  Future<List<VehicleTypeModel>> getAllVehicleTypes() async {
    try {
      final response = await _client
          .from('vehicle_type')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((json) => VehicleTypeModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene un tipo de vehículo por su ID.
  Future<VehicleTypeModel?> getVehicleTypeById(int id) async {
    try {
      final response = await _client
          .from('vehicle_type')
          .select()
          .eq('id', id)
          .single();

      return VehicleTypeModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Crea un nuevo tipo de vehículo (solo para administradores).
  /// 
  /// Retorna [VehicleTypeModel] creado si es exitoso.
  Future<VehicleTypeModel> createVehicleType(String name) async {
    try {
      final response = await _client
          .from('vehicle_type')
          .insert({
            'name': name,
          })
          .select()
          .single();

      return VehicleTypeModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza un tipo de vehículo existente (solo para administradores).
  /// 
  /// Retorna [VehicleTypeModel] actualizado si es exitoso.
  Future<VehicleTypeModel> updateVehicleType(int id, String name) async {
    try {
      final response = await _client
          .from('vehicle_type')
          .update({
            'name': name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return VehicleTypeModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica si un nombre de tipo de vehículo ya existe.
  Future<bool> vehicleTypeNameExists(String name, {int? excludeId}) async {
    try {
      var query = _client
          .from('vehicle_type')
          .select('id')
          .eq('name', name);

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }
}
