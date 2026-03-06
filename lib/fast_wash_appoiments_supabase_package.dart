/// Fast Wash Appointments Supabase Package
/// 
/// Paquete de gestión de citas para lavado de vehículos con Supabase.
/// Implementa arquitectura limpia y está diseñado para ser fácilmente escalable.
/// 
/// Características:
/// - Gestión de perfiles de usuario con validación de cédula ecuatoriana
/// - CRUD de citas de lavado
/// - Catálogo de tipos de vehículos y lavados
/// - Roles de usuario (Cliente y Administrador)
/// - Estados de pago de citas
/// 
/// Uso básico:
/// ```dart
/// import 'package:fast_wash_appoiments_supabase_package/fast_wash_appoiments_supabase_package.dart';
/// 
/// // En tu main.dart, inicializa Supabase
/// await Supabase.initialize(
///   url: 'YOUR_SUPABASE_URL',
///   anonKey: 'YOUR_SUPABASE_ANON_KEY',
/// );
/// 
/// // Crea los controllers
/// final userProfileController = UserProfileController();
/// final appointmentController = AppointmentController();
/// final catalogController = CatalogController();
/// 
/// // Carga el perfil del usuario
/// await userProfileController.loadCurrentUser();
/// 
/// // Verifica si el perfil está completo
/// if (!userProfileController.isProfileComplete) {
///   // Mostrar página de completar perfil
/// }
/// ```
library;

// Models
export 'models/user_model.dart';
export 'models/vehicle_type_model.dart';
export 'models/washed_type_model.dart';
export 'models/appointment_model.dart';

// Services
export 'services/user_service.dart';
export 'services/vehicle_type_service.dart';
export 'services/washed_type_service.dart';
export 'services/appointment_service.dart';

// Controllers
export 'controllers/user_profile_controller.dart';
export 'controllers/appointment_controller.dart';
export 'controllers/catalog_controller.dart';

// Pages
export 'pages/complete_profile_page.dart';
export 'pages/appointment_list_page.dart';
export 'pages/appointment_form_page.dart';
export 'pages/admin_catalog_page.dart';

// Widgets
export 'widgets/appointment_card.dart';

// Utils
export 'utils/validators.dart';

// Re-export Supabase types for convenience
export 'package:supabase_flutter/supabase_flutter.dart' show Supabase, SupabaseClient;
