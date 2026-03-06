import 'package:flutter/material.dart';
import '../controllers/user_profile_controller.dart';
import '../utils/validators.dart';

/// Página para completar el perfil del usuario.
/// 
/// Fuerza al usuario a ingresar su DNI, nombre y apellido
/// antes de poder usar otras funcionalidades del sistema.
class CompleteProfilePage extends StatefulWidget {
  final UserProfileController controller;
  final VoidCallback onProfileCompleted;

  const CompleteProfilePage({
    Key? key,
    required this.controller,
    required this.onProfileCompleted,
  }) : super(key: key);

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-llenar con datos existentes si los hay
    if (widget.controller.currentUser != null) {
      _dniController.text = widget.controller.currentUser!.dni ?? '';
      _firstNameController.text = widget.controller.currentUser!.firstName ?? '';
      _lastNameController.text = widget.controller.currentUser!.lastName ?? '';
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.controller.updateProfile(
      dni: _dniController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      widget.onProfileCompleted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage ?? 'Error al actualizar perfil'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        centerTitle: true,
        automaticallyImplyLeading: false, // No permitir volver atrás
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  'Completa tu perfil',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Para continuar, necesitamos que completes tu información personal.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _dniController,
                  decoration: const InputDecoration(
                    labelText: 'Cédula de Identidad',
                    hintText: '1234567890',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  validator: DniValidator.validateDni,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombres',
                    hintText: 'Juan',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => AppointmentValidators.required(
                    value,
                    fieldName: 'El nombre',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos',
                    hintText: 'Pérez',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => AppointmentValidators.required(
                    value,
                    fieldName: 'El apellido',
                  ),
                ),
                const SizedBox(height: 32),
                ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, child) {
                    return ElevatedButton(
                      onPressed: widget.controller.isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: widget.controller.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Guardar y Continuar',
                              style: TextStyle(fontSize: 16),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Nota: La cédula debe ser ecuatoriana y será validada.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
