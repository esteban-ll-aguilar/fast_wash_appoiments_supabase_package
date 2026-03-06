import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fast_wash_appoiments_supabase_package/fast_wash_appoiments_supabase_package.dart';
import 'package:flutter_login_supabase_packcage/flutter_login_supabase_packcage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// EJEMPLO DE USO INTEGRADO:
/// - Paquete de Login (flutter_login_supabase_packcage)
/// - Paquete de Citas (fast_wash_appoiments_supabase_package)
/// 
/// FLUJO COMPLETO:
/// 1. Login/Registro de usuario
/// 2. Verificación de perfil completo (DNI, nombre, apellido)
/// 3. Sistema de citas y gestión
/// 4. Panel de administración (solo ADMIN)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase con tus credenciales
  try {
    await Supabase.initialize(
      url: 'https://ypiaoxvckjqlarbpdbfl.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwaWFveHZja2pxbGFyYnBkYmZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE3NDg1NTEsImV4cCI6MjA4NzMyNDU1MX0.9sUhkTL5uA5zBWBKUwJp43V3yrYUsmAXA3kVVTqSJYc',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        // En web, deshabilitar auto-refresh puede prevenir errores de OAuth
        autoRefreshToken: true,
      ),
    );
  } catch (e) {
    // Si hay error al recuperar sesión OAuth, limpiar e inicializar de nuevo
    debugPrint('Error al inicializar Supabase: $e');
    // La app continuará sin sesión activa
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fast Wash - Sistema Completo',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AppRoot(),
    );
  }
}

/// Página raíz que maneja el estado de autenticación.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _authController = AuthController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authController,
      builder: (context, child) {
        // Si está autenticado, mostrar el dashboard
        if (_authController.isAuthenticated) {
          return AppointmentDashboard(authController: _authController);
        }

        // Si no está autenticado, mostrar login
        return LoginPage(
          authController: _authController,
          onLoginSuccess: () {
            // El ListenableBuilder se encargará de reconstruir
          },
          onRegisterTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterPage(
                  authController: _authController,
                  onRegisterSuccess: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Dashboard principal del sistema de citas.
class AppointmentDashboard extends StatefulWidget {
  final AuthController authController;

  const AppointmentDashboard({
    Key? key,
    required this.authController,
  }) : super(key: key);

  @override
  State<AppointmentDashboard> createState() => _AppointmentDashboardState();
}

class _AppointmentDashboardState extends State<AppointmentDashboard> {
  final _userProfileController = UserProfileController();
  final _appointmentController = AppointmentController();
  final _catalogController = CatalogController();

  bool _isLoading = true;
  bool _profileComplete = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    // Cargar perfil del usuario
    await _userProfileController.loadCurrentUser();

    // Verificar si el perfil está completo
    _profileComplete = _userProfileController.isProfileComplete;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si el perfil no está completo, mostrar página de completar perfil
    if (!_profileComplete) {
      return CompleteProfilePage(
        controller: _userProfileController,
        onProfileCompleted: () {
          setState(() {
            _profileComplete = true;
          });
        },
      );
    }

    // Si el perfil está completo, mostrar menú principal
    return _buildMainMenu();
  }

  Widget _buildMainMenu() {
    final user = _userProfileController.currentUser;
    final isAdmin = user?.role == UserRole.ADMIN;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Wash'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _showUserMenu,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bienvenida del usuario
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 30,
                        child: Text(
                          user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenido',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                            ),
                            Text(
                              user?.fullName ?? 'Usuario',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              user?.role.displayName ?? 'Cliente',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sección de cliente
          Text(
            'MIS SERVICIOS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          _MenuCard(
            icon: Icons.event,
            title: isAdmin ? 'Citas de Hoy' : 'Mis Citas',
            subtitle: isAdmin 
                ? 'Ver las citas programadas para hoy' 
                : 'Ver y gestionar tus citas',
            color: Colors.green,
            onTap: () async {
              if (isAdmin) {
                await _appointmentController.loadTodayAppointments();
              }
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentListPage(
                    controller: _appointmentController,
                    catalogController: _catalogController,
                    isAdmin: isAdmin,
                  ),
                ),
              );
            },
          ),
          _MenuCard(
            icon: Icons.add_circle,
            title: 'Nueva Cita',
            subtitle: isAdmin 
                ? 'Registrar cita para un cliente' 
                : 'Agendar una nueva cita de lavado',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentFormPage(
                    appointmentController: _appointmentController,
                    catalogController: _catalogController,
                    isAdmin: isAdmin,
                  ),
                ),
              );
            },
          ),

          // Sección de administrador
          if (isAdmin) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'ADMINISTRACIÓN',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.list_alt,
              title: 'Todas las Citas',
              subtitle: 'Ver todas las citas del sistema',
              color: Colors.purple,
              onTap: () async {
                await _appointmentController.loadAllAppointments();
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentListPage(
                      controller: _appointmentController,
                      catalogController: _catalogController,
                      isAdmin: true,
                    ),
                  ),
                );
              },
            ),
            _MenuCard(
              icon: Icons.settings,
              title: 'Gestionar Catálogo',
              subtitle: 'Tipos de vehículos y lavados',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminCatalogPage(
                      catalogController: _catalogController,
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 24),

          // Información adicional
          Card(
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Información',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Las citas deben agendarse con anticipación\n'
                    '• Recuerda llegar 5 minutos antes\n'
                    '• El pago se realiza después del servicio\n'
                    '• No se permiten cancelaciones',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserMenu() {
    final user = _userProfileController.currentUser;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user?.fullName ?? 'Usuario'),
              subtitle: Text(user?.email ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('DNI'),
              trailing: Text(
                user?.dni ?? 'N/A',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Rol'),
              trailing: Text(
                user?.role.displayName ?? 'Cliente',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Editar Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompleteProfilePage(
                      controller: _userProfileController,
                      onProfileCompleted: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                Navigator.pop(context);
                await widget.authController.logout();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Widget reutilizable para las tarjetas del menú.
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Página principal del demo que muestra cómo usar el paquete.
class AppointmentDemoHome extends StatefulWidget {
  const AppointmentDemoHome({super.key});

  @override
  State<AppointmentDemoHome> createState() => _AppointmentDemoHomeState();
}

class _AppointmentDemoHomeState extends State<AppointmentDemoHome> {
  // Controllers del paquete
  final _userProfileController = UserProfileController();
  final _appointmentController = AppointmentController();
  final _catalogController = CatalogController();

  bool _isLoading = true;
  bool _profileComplete = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Inicializa la aplicación verificando el estado del perfil.
  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    // Cargar perfil del usuario
    // NOTA: En una app real, primero debes autenticar con el paquete de login
    await _userProfileController.loadCurrentUser();

    // Verificar si el perfil está completo
    _profileComplete = _userProfileController.isProfileComplete;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si el perfil no está completo, mostrar página de completar perfil
    if (!_profileComplete) {
      return CompleteProfilePage(
        controller: _userProfileController,
        onProfileCompleted: () {
          setState(() {
            _profileComplete = true;
          });
        },
      );
    }

    // Si el perfil está completo, mostrar menú principal
    return _buildMainMenu();
  }

  Widget _buildMainMenu() {
    final user = _userProfileController.currentUser;
    final isAdmin = user?.role == UserRole.ADMIN;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Wash Appointments'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              _showUserInfo();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Información del usuario
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido, ${user?.fullName ?? 'Usuario'}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rol: ${user?.role.displayName ?? 'Cliente'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'DNI: ${user?.dni ?? 'N/A'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Opciones del menú
          _MenuCard(
            icon: Icons.event,
            title: 'Mis Citas',
            subtitle: 'Ver y gestionar tus citas',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentListPage(
                    controller: _appointmentController,
                    isAdmin: isAdmin,
                  ),
                ),
              );
            },
          ),
          _MenuCard(
            icon: Icons.add_circle,
            title: 'Nueva Cita',
            subtitle: 'Agendar una nueva cita',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentFormPage(
                    appointmentController: _appointmentController,
                    catalogController: _catalogController,
                  ),
                ),
              );
            },
          ),
          
          // Opciones solo para administradores
          if (isAdmin) ...[
            const SizedBox(height: 16),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'ADMINISTRACIÓN',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
            _MenuCard(
              icon: Icons.settings,
              title: 'Gestionar Catálogo',
              subtitle: 'Tipos de vehículos y lavados',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminCatalogPage(
                      catalogController: _catalogController,
                    ),
                  ),
                );
              },
            ),
            _MenuCard(
              icon: Icons.list_alt,
              title: 'Todas las Citas',
              subtitle: 'Ver todas las citas del sistema',
              color: Colors.purple,
              onTap: () async {
                await _appointmentController.loadAllAppointments();
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentListPage(
                      controller: _appointmentController,
                      isAdmin: true,
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 24),

          // Información del paquete
          Card(
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acerca del Demo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Este es un ejemplo de uso del paquete Fast Wash Appointments.\n\n'
                    'Funcionalidades:\n'
                    '• Validación de cédula ecuatoriana\n'
                    '• Gestión de perfil de usuario\n'
                    '• Creación y visualización de citas\n'
                    '• Panel de administración\n'
                    '• Integración con Supabase',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserInfo() {
    final user = _userProfileController.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user?.email ?? 'N/A'}'),
            Text('Nombre: ${user?.fullName ?? 'N/A'}'),
            Text('DNI: ${user?.dni ?? 'N/A'}'),
            Text('Rol: ${user?.role.displayName ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

//
