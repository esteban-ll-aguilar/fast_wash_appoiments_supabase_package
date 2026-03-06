import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/user_profile_controller.dart';
import '../utils/validators.dart';

/// Página para completar el perfil del usuario con diseño profesional.
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

class _CompleteProfilePageState extends State<CompleteProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Pre-llenar con datos existentes si los hay
    if (widget.controller.currentUser != null) {
      _dniController.text = widget.controller.currentUser!.dni ?? '';
      _firstNameController.text = widget.controller.currentUser!.firstName ?? '';
      _lastNameController.text = widget.controller.currentUser!.lastName ?? '';
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.controller.errorMessage ?? 'Error al actualizar perfil',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Spacer(),
                        _buildHeader(colorScheme),
                        const SizedBox(height: 48),
                        _buildForm(colorScheme),
                        const SizedBox(height: 24),
                        _buildNote(colorScheme),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.person_rounded,
            size: 64,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Completa tu Perfil',
          style: GoogleFonts.dmSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Para continuar, necesitamos que\ncompletes tu información personal.',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _dniController,
              decoration: InputDecoration(
                labelText: 'Cédula de Identidad',
                labelStyle: GoogleFonts.dmSans(),
                hintText: '1234567890',
                hintStyle: GoogleFonts.dmSans(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                prefixIcon: const Icon(Icons.badge_rounded),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
              style: GoogleFonts.dmSans(fontSize: 15),
              keyboardType: TextInputType.number,
              maxLength: 10,
              validator: DniValidator.validateDni,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'Nombres',
                labelStyle: GoogleFonts.dmSans(),
                hintText: 'Juan Carlos',
                hintStyle: GoogleFonts.dmSans(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                prefixIcon: const Icon(Icons.person_outline_rounded),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.dmSans(fontSize: 15),
              textCapitalization: TextCapitalization.words,
              validator: (value) => AppointmentValidators.required(
                value,
                fieldName: 'El nombre',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Apellidos',
                labelStyle: GoogleFonts.dmSans(),
                hintText: 'Pérez González',
                hintStyle: GoogleFonts.dmSans(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                prefixIcon: const Icon(Icons.person_rounded),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.dmSans(fontSize: 15),
              textCapitalization: TextCapitalization.words,
              validator: (value) => AppointmentValidators.required(
                value,
                fieldName: 'El apellido',
              ),
            ),
            const SizedBox(height: 24),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, child) {
                return FilledButton(
                  onPressed: widget.controller.isLoading ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: widget.controller.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Guardar y Continuar',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNote(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_rounded,
            color: Colors.orange[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'La cédula debe ser ecuatoriana y será validada.',
              style: GoogleFonts.dmSans(
                color: Colors.orange[900],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
