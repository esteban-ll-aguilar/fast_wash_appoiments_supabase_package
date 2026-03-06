# Fast Wash Appointments Supabase Package

Paquete Flutter para gestión de citas de lavado de vehículos con integración a Supabase. Diseñado como módulo reutilizable con arquitectura limpia.

## ✨ Características

- ✅ **Validación de cédula ecuatoriana** - Algoritmo oficial de validación
- 👤 **Gestión de perfil de usuario** - Verificación de perfil completo
- 📅 **CRUD de citas** - Creación, lectura y actualización de citas
- 🚗 **Catálogo de servicios** - Tipos de vehículos y lavados
- 👥 **Roles de usuario** - Cliente y Administrador
- 💰 **Estados de pago** - Pagado y Pendiente
- 🔒 **Integración con Supabase** - Base de datos y autenticación
- 📱 **Material Design 3** - UI moderna y responsiva

## 📋 Requisitos

- Flutter SDK: `>=3.10.8`
- Supabase configurado con las tablas necesarias
- Paquete de autenticación (recomendado: `flutter_login_supabase_packcage`)

## 🚀 Instalación

### 1. Agregar al `pubspec.yaml`

```yaml
dependencies:
  fast_wash_appoiments_supabase_package:
    path: ../fast_wash_appoiments_supabase_package  # o tu ruta
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Supabase

En tu `main.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(MyApp());
}
```

## 🗄️ Configuración de Base de Datos

### Tablas necesarias

Ejecuta estas migraciones SQL en tu proyecto de Supabase:

```sql
-- Tipos ENUM
CREATE TYPE user_role AS ENUM ('ADMIN', 'CLIENT');
CREATE TYPE appointment_status AS ENUM ('PAYMENT', 'UNPAYMENT');

-- Tabla VehicleType
CREATE TABLE vehicle_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla User (requiere auth.users de Supabase)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    dni VARCHAR(20) UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    role user_role NOT NULL DEFAULT 'CLIENT',
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla WashedType
CREATE TABLE washed_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    vehicle_type_id INTEGER NOT NULL REFERENCES vehicle_type(id) ON DELETE RESTRICT,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(name, vehicle_type_id)
);

-- Tabla Appointment
CREATE TABLE appointment (
    id SERIAL PRIMARY KEY,
    user_dni VARCHAR(20) NOT NULL REFERENCES users(dni) ON DELETE CASCADE,
    washed_type_id INTEGER NOT NULL REFERENCES washed_type(id) ON DELETE RESTRICT,
    status appointment_status NOT NULL DEFAULT 'UNPAYMENT',
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (appointment_date >= CURRENT_DATE)
);

-- Función para crear usuario automáticamente al registrarse
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    INSERT INTO public.users (
        id,
        email,
        role,
        first_name,
        last_name,
        dni,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        'CLIENT',
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'dni', NULL),
        NEW.created_at,
        NEW.created_at
    );
    
    RETURN NEW;
END;
$$;

-- Trigger para crear usuario
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_washed_type_updated_at BEFORE UPDATE ON washed_type
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointment_updated_at BEFORE UPDATE ON appointment
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vehicle_type_updated_at BEFORE UPDATE ON vehicle_type
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Índices
CREATE INDEX idx_appointment_date ON appointment(appointment_date);
CREATE INDEX idx_appointment_user ON appointment(user_dni);
CREATE INDEX idx_appointment_status ON appointment(status);
```

## 💡 Uso Básico

### 1. Inicializar Controllers

```dart
import 'package:fast_wash_appoiments_supabase_package/fast_wash_appoiments_supabase_package.dart';

// Crear controllers
final userProfileController = UserProfileController();
final appointmentController = AppointmentController();
final catalogController = CatalogController();
```

### 2. Verificar perfil completo

```dart
// Cargar perfil del usuario
await userProfileController.loadCurrentUser();

// Verificar si está completo
if (!userProfileController.isProfileComplete) {
  // Mostrar página de completar perfil
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CompleteProfilePage(
        controller: userProfileController,
        onProfileCompleted: () {
          // Perfil completado, continuar
        },
      ),
    ),
  );
}
```

### 3. Listar citas del usuario

```dart
// Cargar citas
await appointmentController.loadUserAppointments();

// Mostrar lista de citas
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AppointmentListPage(
      controller: appointmentController,
    ),
  ),
);
```

### 4. Crear nueva cita

```dart
// Navegar a formulario de cita
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AppointmentFormPage(
      appointmentController: appointmentController,
      catalogController: catalogController,
    ),
  ),
);
```

### 5. Panel de administrador

```dart
// Solo para usuarios con rol ADMIN
if (user.role == UserRole.ADMIN) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AdminCatalogPage(
        catalogController: catalogController,
      ),
    ),
  );
}
```

## 📚 Componentes Principales

### Controllers

- **`UserProfileController`** - Gestiona el perfil del usuario
- **`AppointmentController`** - Gestiona las citas
- **`CatalogController`** - Gestiona tipos de vehículos y lavados

### Páginas

- **`CompleteProfilePage`** - Formulario para completar perfil con validación de DNI
- **`AppointmentListPage`** - Lista de citas filtrable
- **`AppointmentFormPage`** - Formulario para crear citas
- **`AdminCatalogPage`** - Panel de administración

### Modelos

- **`UserModel`** - Usuario con DNI, rol y datos personales
- **`VehicleTypeModel`** - Tipo de vehículo (Sedan, SUV, etc.)
- **`WashedTypeModel`** - Tipo de lavado con precio
- **`AppointmentModel`** - Cita con fecha, hora y estado

### Validadores

- **`DniValidator`** - Validación de cédula ecuatoriana
- **`AppointmentValidators`** - Validadores para formularios

## 🔐 Roles y Permisos

### Cliente (CLIENT)
- ✅ Ver sus propias citas
- ✅ Crear nuevas citas
- ❌ No puede cancelar citas
- ❌ No puede ver citas de otros usuarios

### Administrador (ADMIN)
- ✅ Ver todas las citas
- ✅ Crear/editar citas
- ✅ Gestionar tipos de vehículos
- ✅ Gestionar tipos de lavados
- ✅ Cambiar estado de pago de citas

## 🎨 Widgets Personalizables

### AppointmentCard

```dart
AppointmentCard(
  appointment: appointment,
  isAdmin: true,
  onTap: () {
    // Acción al tocar la tarjeta
  },
)
```

## 🧪 Ejemplo Completo

Ver [example/lib/main.dart](example/lib/main.dart) para un ejemplo completo de integración.

## 🤝 Integración con Login Package

Este paquete está diseñado para trabajar junto con `flutter_login_supabase_packcage`:

```dart
// 1. Autenticar usuario
final authController = AuthController();
await authController.login(email, password);

// 2. Verificar perfil completo
final userProfileController = UserProfileController();
await userProfileController.loadCurrentUser();

if (!userProfileController.isProfileComplete) {
  // Mostrar CompleteProfilePage
}
```

## 📝 Notas Importantes

1. **DNI Obligatorio**: Los usuarios deben completar su perfil con un DNI ecuatoriano válido antes de crear citas.

2. **Validación de DNI**: El paquete implementa el algoritmo oficial de validación de cédulas ecuatorianas.

3. **Horarios Únicos**: El sistema verifica que no se agenden dos citas en el mismo horario.

4. **Fechas Futuras**: Solo se permiten citas en fechas futuras o la fecha actual.

5. **Sin Eliminación**: Por diseño, no se permite eliminar tipos de vehículos o lavados para mantener integridad de datos.

## 🐛 Solución de Problemas

### Error: "Usuario no tiene DNI registrado"
- Asegúrate de que el usuario haya completado su perfil usando `CompleteProfilePage`.

### Error: "Este horario ya está ocupado"
- Selecciona otro horario. El sistema no permite citas duplicadas.

### Error al cargar citas
- Verifica que las tablas estén creadas correctamente en Supabase.
- Revisa que los permisos RLS (Row Level Security) estén configurados.

## 📄 Licencia

Este paquete es privado y está destinado para uso interno del proyecto Fast Wash.

## 👥 Autores

Desarrollado como módulo reutilizable para el sistema de gestión de lavado de vehículos Fast Wash.
