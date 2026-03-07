import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import '../controllers/appointment_controller.dart';
import '../controllers/catalog_controller.dart';
import '../models/vehicle_type_model.dart';
import '../models/washed_type_model.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../utils/validators.dart';

/// Pagina para crear o editar una cita con diseno profesional.
class AppointmentFormPage extends StatefulWidget {
  final AppointmentController appointmentController;
  final CatalogController catalogController;
  final bool isAdmin;
  final AppointmentModel? appointment;

  const AppointmentFormPage({
    Key? key,
    required this.appointmentController,
    required this.catalogController,
    this.isAdmin = false,
    this.appointment,
  }) : super(key: key);

  @override
  State<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _userService = UserService();

  VehicleTypeModel? _selectedVehicleType;
  WashedTypeModel? _selectedWashedType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  AppointmentStatus _selectedStatus = AppointmentStatus.UNPAYMENT;
  UserModel? _selectedUser;

  bool _isSubmitting = false;
  bool _isSearchingUser = false;
  bool get _isEditing => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    if (_isEditing) {
      _loadAppointmentData();
    }
  }

  Future<void> _loadAppointmentData() async {
    final apt = widget.appointment!;

    if (widget.isAdmin) {
      _dniController.text = apt.userDni;
      try {
        _selectedUser = await _userService.getUserByDni(apt.userDni);
      } catch (e) {
        debugPrint('Error loading user: $e');
      }
    }

    _selectedDate = apt.appointmentDate;
    final timeParts = apt.appointmentTime.split(':');
    _selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    _selectedStatus = apt.status;
    setState(() {});
  }

  @override
  void dispose() {
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    await widget.catalogController.loadCatalog();

    if (_isEditing && mounted) {
      final apt = widget.appointment!;
      _selectedWashedType = widget.catalogController.washedTypes.firstWhere(
          (wt) => wt.id == apt.washedTypeId,
          orElse: () => widget.catalogController.washedTypes.first);

      if (_selectedWashedType != null) {
        _selectedVehicleType = widget.catalogController.vehicleTypes
            .firstWhere((vt) => vt.id == _selectedWashedType!.vehicleTypeId);
      }

      setState(() {});
    }
  }

  Future<void> _searchUserByDni() async {
    if (_dniController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un DNI'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!DniValidator.isValidEcuadorianDni(_dniController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('DNI invalido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSearchingUser = true;
    });

    try {
      final user =
          await _userService.getUserByDni(_dniController.text.trim());

      setState(() {
        _selectedUser = user;
        _isSearchingUser = false;
      });

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario no encontrado'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario encontrado: ${user.fullName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSearchingUser = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 1, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es', 'ES'),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          _selectedTime = null;
        }
      });
    }
  }

  Future<void> _selectTime() async {
    final now = DateTime.now();
    final isToday = _selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;

    TimeOfDay initialTime;
    if (isToday) {
      final nowPlus5 = now.add(const Duration(minutes: 5));
      initialTime =
          TimeOfDay(hour: nowPlus5.hour, minute: nowPlus5.minute);
    } else {
      initialTime = _selectedTime ?? const TimeOfDay(hour: 8, minute: 0);
    }

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null) {
      if (isToday) {
        final selectedDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          time.hour,
          time.minute,
        );

        final minimumTime = now.add(const Duration(minutes: 5));

        if (selectedDateTime.isBefore(minimumTime)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'La hora debe ser al menos 5 minutos despues de ahora'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      setState(() {
        _selectedTime = time;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isAdmin && _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Busca y selecciona un usuario por su DNI'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedWashedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un tipo de lavado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una fecha'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una hora'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final minimumTime = DateTime.now().add(const Duration(minutes: 5));

    if (selectedDateTime.isBefore(minimumTime) && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '¡La fecha y hora deben ser futuras! (Al menos 5 minutos desde ahora)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final timeString = _formatTime(_selectedTime!);

    bool needsAvailabilityCheck = true;
    if (_isEditing) {
      final apt = widget.appointment!;
      final sameDate =
          _selectedDate!.isAtSameMomentAs(apt.appointmentDate);
      final sameTime = timeString == apt.appointmentTime;
      needsAvailabilityCheck = !(sameDate && sameTime);
    }

    if (needsAvailabilityCheck) {
      final isAvailable =
          await widget.appointmentController.isTimeSlotAvailable(
        date: _selectedDate!,
        time: timeString,
        excludeAppointmentId: _isEditing ? widget.appointment!.id : null,
      );

      if (!isAvailable) {
        setState(() {
          _isSubmitting = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Este horario ya esta ocupado. Selecciona otro.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    AppointmentModel? appointment;

    if (_isEditing) {
      appointment = await widget.appointmentController.updateAppointment(
        id: widget.appointment!.id,
        washedTypeId: _selectedWashedType!.id,
        appointmentDate: _selectedDate!,
        appointmentTime: timeString,
        status: _selectedStatus,
      );
    } else {
      appointment = await widget.appointmentController.createAppointment(
        washedTypeId: _selectedWashedType!.id,
        appointmentDate: _selectedDate!,
        appointmentTime: timeString,
        userDni: widget.isAdmin ? _selectedUser!.dni : null,
        status: widget.isAdmin ? _selectedStatus : null,
      );
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (appointment != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Cita actualizada exitosamente'
              : 'Cita creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.appointmentController.errorMessage ??
                (_isEditing
                    ? 'Error al actualizar la cita'
                    : 'Error al crear la cita'),
          ),
          backgroundColor: Colors.red,
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                _isEditing ? 'Editar Cita' : 'Nueva Cita',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: widget.catalogController,
              builder: (context, child) {
                if (widget.catalogController.isLoading) {
                  return SizedBox(
                    height: 400,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 3,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.spacing16),
                          Text(
                            'Cargando opciones...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return FWResponsiveCenter(
                  maxWidth: 600,
                  padding: const EdgeInsets.all(AppSpacing.spacing20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.isAdmin)
                          _buildClientSearchSection(colorScheme, theme),
                        if (widget.isAdmin)
                          const SizedBox(height: AppSpacing.spacing20),
                        _buildServiceSelectionSection(colorScheme, theme),
                        const SizedBox(height: AppSpacing.spacing20),
                        _buildDateTimeSection(colorScheme, theme),
                        const SizedBox(height: AppSpacing.spacing20),
                        if (widget.isAdmin)
                          _buildPaymentStatusSection(colorScheme, theme),
                        if (widget.isAdmin)
                          const SizedBox(height: AppSpacing.spacing20),
                        _buildSubmitButton(colorScheme, theme),
                        const SizedBox(height: AppSpacing.spacing40),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSearchSection(
      ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_search_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing12),
              Text(
                'Datos del Cliente',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CUTextField(
                  controller: _dniController,
                  labelText: 'DNI del Cliente',
                  hintText: '0123456789',
                  prefixIcon: const Icon(Icons.badge_rounded),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  showCounter: false,
                  enabled: !_isSearchingUser && !_isEditing,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing12),
              FWButton(
                text: 'Buscar',
                onPressed: (_isSearchingUser || _isEditing)
                    ? null
                    : _searchUserByDni,
                isLoading: _isSearchingUser,
                icon: const Icon(Icons.search_rounded, size: 20),
                expand: false,
              ),
            ],
          ),
          if (_selectedUser != null) ...[
            const SizedBox(height: AppSpacing.spacing16),
            Container(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green[50]!,
                    Colors.green[100]!.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.green[300]!, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedUser!.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DNI: ${_selectedUser!.dni}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isEditing)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        setState(() {
                          _selectedUser = null;
                          _dniController.clear();
                        });
                      },
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.green[700],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceSelectionSection(
      ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_car_wash_rounded,
                  color: colorScheme.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing12),
              Text(
                'Seleccion de Servicio',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing20),
          if (widget.catalogController.vehicleTypes.isEmpty)
            _buildWarningCard(
              icon: Icons.warning_amber_rounded,
              title: 'No hay tipos de vehiculo',
              message:
                  'El administrador debe crear tipos de vehiculo primero.',
              colorScheme: colorScheme,
              theme: theme,
            )
          else
            CUDropdownField<VehicleTypeModel>(
              value: _selectedVehicleType,
              labelText: 'Tipo de Vehiculo',
              prefixIcon: const Icon(Icons.directions_car_rounded),
              items: widget.catalogController.vehicleTypes
                  .map((vt) => DropdownMenuItem(
                        value: vt,
                        child: Text(vt.name),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehicleType = value;
                  _selectedWashedType = null;
                });
              },
              validator: (value) {
                if (value == null) return 'Selecciona un tipo de vehiculo';
                return null;
              },
            ),
          const SizedBox(height: AppSpacing.spacing16),
          if (_selectedVehicleType != null)
            Builder(
              builder: (context) {
                final washedTypes = widget.catalogController
                    .getWashedTypesByVehicle(_selectedVehicleType!.id);

                if (washedTypes.isEmpty) {
                  return _buildWarningCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'No hay tipos de lavado',
                    message:
                        'No hay lavados disponibles para ${_selectedVehicleType!.name}.',
                    colorScheme: colorScheme,
                    theme: theme,
                  );
                }

                return CUDropdownField<WashedTypeModel>(
                  value: _selectedWashedType,
                  labelText: 'Tipo de Lavado',
                  prefixIcon: const Icon(Icons.car_repair_rounded),
                  items: washedTypes
                      .map((wt) => DropdownMenuItem(
                            value: wt,
                            child:
                                Text('${wt.name} - ${wt.formattedPrice}'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedWashedType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecciona un tipo de lavado';
                    }
                    return null;
                  },
                );
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.spacing12),
                  Expanded(
                    child: Text(
                      'Primero selecciona un tipo de vehiculo',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection(
      ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_rounded,
                  color: colorScheme.tertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing12),
              Text(
                'Fecha y Hora',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing20),
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha de la Cita',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDate == null
                              ? 'Seleccionar fecha'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _selectedDate == null
                                ? colorScheme.onSurfaceVariant
                                    .withOpacity(0.6)
                                : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          InkWell(
            onTap: _selectTime,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hora de la Cita',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTime == null
                              ? 'Seleccionar hora'
                              : _selectedTime!.format(context),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _selectedTime == null
                                ? colorScheme.onSurfaceVariant
                                    .withOpacity(0.6)
                                : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusSection(
      ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.payments_rounded,
                  color: Colors.green[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing12),
              Text(
                'Estado de Pago',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          CUDropdownField<AppointmentStatus>(
            value: _selectedStatus,
            labelText: 'Estado',
            prefixIcon: const Icon(Icons.payment_rounded),
            items: AppointmentStatus.values
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(
                            status == AppointmentStatus.PAYMENT
                                ? Icons.check_circle_rounded
                                : Icons.pending_rounded,
                            color: status == AppointmentStatus.PAYMENT
                                ? Colors.green
                                : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(status.displayName),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedStatus = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme, ThemeData theme) {
    return FWButton(
      text: _isEditing ? 'Actualizar Cita' : 'Crear Cita',
      onPressed: _handleSubmit,
      isLoading: _isSubmitting,
    );
  }

  Widget _buildWarningCard({
    required IconData icon,
    required String title,
    required String message,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange[700], size: 28),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
