import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/washed_type_model.dart';

/// Servicio para gestionar operaciones relacionadas con tipos de lavado en Supabase.
class WashedTypeService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todos los tipos de lavado disponibles.
  /// 
  /// Incluye información del tipo de vehículo relacionado.
  Future<List<WashedTypeModel>> getAllWashedTypes() async {
    try {
      final response = await _client
          .from('washed_type')
          .select('*, vehicle_type(name)')
          .order('name', ascending: true);

      return (response as List)
          .map((json) => WashedTypeModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene un tipo de lavado por su ID.
  Future<WashedTypeModel?> getWashedTypeById(int id) async {
    try {
      final response = await _client
          .from('washed_type')
          .select('*, vehicle_type(name)')
          .eq('id', id)
          .single();

      return WashedTypeModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene tipos de lavado filtrados por tipo de vehículo.
  Future<List<WashedTypeModel>> getWashedTypesByVehicleType(int vehicleTypeId) async {
    try {
      final response = await _client
          .from('washed_type')
          .select('*, vehicle_type(name)')
          .eq('vehicle_type_id', vehicleTypeId)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => WashedTypeModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Crea un nuevo tipo de lavado (solo para administradores).
  /// 
  /// Retorna [WashedTypeModel] creado si es exitoso.
  Future<WashedTypeModel> createWashedType({
    required String name,
    required int vehicleTypeId,
    required double price,
  }) async {
    try {
      final response = await _client
          .from('washed_type')
          .insert({
            'name': name,
            'vehicle_type_id': vehicleTypeId,
            'price': price,
          })
          .select('*, vehicle_type(name)')
          .single();

      return WashedTypeModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza un tipo de lavado existente (solo para administradores).
  /// 
  /// Retorna [WashedTypeModel] actualizado si es exitoso.
  Future<WashedTypeModel> updateWashedType({
    required int id,
    String? name,
    int? vehicleTypeId,
    double? price,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (vehicleTypeId != null) updateData['vehicle_type_id'] = vehicleTypeId;
      if (price != null) updateData['price'] = price;

      final response = await _client
          .from('washed_type')
          .update(updateData)
          .eq('id', id)
          .select('*, vehicle_type(name)')
          .single();

      return WashedTypeModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica si ya existe un tipo de lavado con el mismo nombre para un vehículo.
  Future<bool> washedTypeExists({
    required String name,
    required int vehicleTypeId,
    int? excludeId,
  }) async {
    try {
      var query = _client
          .from('washed_type')
          .select('id')
          .eq('name', name)
          .eq('vehicle_type_id', vehicleTypeId);

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
