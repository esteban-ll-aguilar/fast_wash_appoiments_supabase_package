import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import '../controllers/user_profile_controller.dart';
import '../models/document_type.dart';
import '../utils/validators.dart';

/// Pagina para completar el perfil del usuario con diseno profesional.
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
  DocumentType _selectedType = DocumentType.cedula;

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

    if (widget.controller.currentUser != null) {
      _dniController.text = widget.controller.currentUser!.dni ?? '';
      _firstNameController.text =
          widget.controller.currentUser!.firstName ?? '';
      _lastNameController.text =
          widget.controller.currentUser!.lastName ?? '';
    }

    if (widget.controller.currentUser != null) {
      _selectedType = widget.controller.currentUser!.documentType;
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
      documentType: _selectedType,
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
              const SizedBox(width: AppSpacing.spacing12),
              Expanded(
                child: Text(
                  widget.controller.errorMessage ??
                      'Error al actualizar perfil',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

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
                  child: FWResponsiveCenter(
                    maxWidth: 600,
                    padding: const EdgeInsets.all(AppSpacing.spacing24),
                    child: Column(
                      children: [
                        const Spacer(),
                        _buildHeader(colorScheme, theme),
                        const SizedBox(height: AppSpacing.spacing48),
                        _buildForm(colorScheme, theme),
                        const SizedBox(height: AppSpacing.spacing24),
                        _buildNote(colorScheme, theme),
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

  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
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
        const SizedBox(height: AppSpacing.spacing24),
        Text(
          'Completa tu Perfil',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.spacing12),
        Text(
          'Para continuar, necesitamos que\ncompletes tu informacion personal.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing24),
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
            SegmentedButton<DocumentType>(
              segments: const [
                ButtonSegment(
                  value: DocumentType.cedula,
                  label: Text('Cedula'),
                  icon: Icon(Icons.badge_rounded),
                ),
                ButtonSegment(
                  value: DocumentType.ruc,
                  label: Text('RUC'),
                  icon: Icon(Icons.business_rounded),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (value) {
                setState(() {
                  _selectedType = value.first;
                  _dniController.clear();
                });
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: colorScheme.primary,
                selectedForegroundColor: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            CUTextField(
              controller: _dniController,
              labelText: _selectedType == DocumentType.cedula
                  ? 'Cedula de Identidad'
                  : 'RUC',
              hintText: _selectedType == DocumentType.cedula
                  ? '1234567890'
                  : '1234567890001',
              prefixIcon: const Icon(Icons.badge_rounded),
              keyboardType: TextInputType.number,
              maxLength: _selectedType == DocumentType.cedula ? 10 : 13,
              showCounter: false,
              validator: (value) =>
                  DniValidator.validateDocument(value, _selectedType),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            CUTextField(
              controller: _firstNameController,
              labelText: 'Nombres',
              hintText: 'Juan Carlos',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              textCapitalization: TextCapitalization.words,
              validator: (value) => AppointmentValidators.required(
                value,
                fieldName: 'El nombre',
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            CUTextField(
              controller: _lastNameController,
              labelText: 'Apellidos',
              hintText: 'Perez Gonzalez',
              prefixIcon: const Icon(Icons.person_rounded),
              textCapitalization: TextCapitalization.words,
              validator: (value) => AppointmentValidators.required(
                value,
                fieldName: 'El apellido',
              ),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, child) {
                return FWButton(
                  text: 'Guardar y Continuar',
                  onPressed: _handleSubmit,
                  isLoading: widget.controller.isLoading,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNote(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
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
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Text(
              _selectedType == DocumentType.cedula
                  ? 'La cedula debe ser ecuatoriana (10 digitos) y sera validada.'
                  : 'El RUC debe ser ecuatoriano (13 digitos) y sera validado.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
