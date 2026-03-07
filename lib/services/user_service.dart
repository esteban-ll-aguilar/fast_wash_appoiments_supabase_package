import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_type.dart';
import '../models/user_model.dart';

/// Servicio para gestionar operaciones relacionadas con usuarios en Supabase.
/// 
/// Maneja la actualización de perfiles de usuario, especialmente
/// la información personal como DNI, nombre y apellido.
class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene los datos del usuario actual desde la tabla 'users'.
  /// 
  /// Retorna [UserModel] si el usuario existe, null en caso contrario.
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene un usuario por su ID.
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene un usuario por su DNI.
  Future<UserModel?> getUserByDni(String dni) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('dni', dni)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza el perfil del usuario actual.
  /// 
  /// Permite actualizar DNI, nombre y apellido.
  /// Retorna [UserModel] actualizado si es exitoso.
  Future<UserModel> updateUserProfile({
    String? dni,
    String? firstName,
    String? lastName,
    DocumentType? documentType,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (dni != null) updateData['dni'] = dni;
      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (documentType != null) updateData['document_type'] = documentType.dbValue;

      final response = await _client
          .from('users')
          .update(updateData)
          .eq('id', user.id)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica si el perfil del usuario actual está completo.
  /// 
  /// Un perfil está completo si tiene DNI, nombre y apellido.
  Future<bool> isProfileComplete() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;
      return user.isProfileComplete;
    } catch (e) {
      return false;
    }
  }

  /// Lista todos los usuarios (solo para administradores).
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza el rol de un usuario (solo para administradores).
  Future<UserModel> updateUserRole(String userId, UserRole role) async {
    try {
      final response = await _client
          .from('users')
          .update({
            'role': role.name.toUpperCase(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
