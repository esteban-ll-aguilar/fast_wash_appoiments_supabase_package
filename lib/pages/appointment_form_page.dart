import 'package:flutter/material.dart';
import '../controllers/appointment_controller.dart';
import '../controllers/catalog_controller.dart';
import '../models/vehicle_type_model.dart';
import '../models/washed_type_model.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../utils/validators.dart';

/// Página para crear o editar una cita.
class AppointmentFormPage extends StatefulWidget {
  final AppointmentController appointmentController;
  final CatalogController catalogController;
  final bool isAdmin;
  final AppointmentModel? appointment; // Para edición

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

  /// Carga los datos del appointment para edición
  Future<void> _loadAppointmentData() async {
    final apt = widget.appointment!;
    
    // Cargar usuario si es admin
    if (widget.isAdmin) {
      _dniController.text = apt.userDni;
      try {
        _selectedUser = await _userService.getUserByDni(apt.userDni);
      } catch (e) {
        debugPrint('Error loading user: $e');
      }
    }
    
    // Cargar fecha y hora
    _selectedDate = apt.appointmentDate;
    final timeParts = apt.appointmentTime.split(':');
    _selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    
    // Cargar estado
    _selectedStatus = apt.status;
    
    // Los tipos de vehículo y lavado se cargarán después del catálogo
    setState(() {});
  }

  @override
  void dispose() {
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    await widget.catalogController.loadCatalog();
    
    // Si está editando, seleccionar el tipo de lavado correcto
    if (_isEditing && mounted) {
      final apt = widget.appointment!;
      _selectedWashedType = widget.catalogController.washedTypes
          .firstWhere((wt) => wt.id == apt.washedTypeId, orElse: () => widget.catalogController.washedTypes.first);
      
      // Seleccionar el tipo de vehículo correcto
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
          content: Text('DNI inválido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSearchingUser = true;
    });

    try {
      final user = await _userService.getUserByDni(_dniController.text.trim());
      
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
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es', 'ES'),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
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

    // Validar usuario si es admin
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

    setState(() {
      _isSubmitting = true;
    });

    final timeString = _formatTime(_selectedTime!);
    
    // Verificar disponibilidad (solo si no está editando o si cambió fecha/hora)
    bool needsAvailabilityCheck = true;
    if (_isEditing) {
      final apt = widget.appointment!;
      final sameDate = _selectedDate!.isAtSameMomentAs(apt.appointmentDate);
      final sameTime = timeString == apt.appointmentTime;
      needsAvailabilityCheck = !(sameDate && sameTime);
    }
    
    if (needsAvailabilityCheck) {
      final isAvailable = await widget.appointmentController.isTimeSlotAvailable(
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
            content: Text('Este horario ya está ocupado. Selecciona otro.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    AppointmentModel? appointment;
    
    if (_isEditing) {
      // Actualizar cita existente
      appointment = await widget.appointmentController.updateAppointment(
        id: widget.appointment!.id,
        washedTypeId: _selectedWashedType!.id,
        appointmentDate: _selectedDate!,
        appointmentTime: timeString,
        status: _selectedStatus,
      );
    } else {
      // Crear nueva cita
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
          content: Text(_isEditing ? 'Cita actualizada exitosamente' : 'Cita creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.appointmentController.errorMessage ?? 
            (_isEditing ? 'Error al actualizar la cita' : 'Error al crear la cita'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Cita' : 'Nueva Cita'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: widget.catalogController,
        builder: (context, child) {
          if (widget.catalogController.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de búsqueda de usuario (solo admin)
                  if (widget.isAdmin) ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Datos del Cliente',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _dniController,
                                    decoration: const InputDecoration(
                                      labelText: 'DNI del Cliente',
                                      hintText: '0123456789',
                                      prefixIcon: Icon(Icons.badge),
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    maxLength: 10,
                                    enabled: !_isSearchingUser && !_isEditing, // Deshabilitar en edición
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: (_isSearchingUser || _isEditing) ? null : _searchUserByDni,
                                  icon: _isSearchingUser
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.search),
                                  label: const Text('Buscar'),
                                ),
                              ],
                            ),
                            if (_selectedUser != null) ...[
                              const Divider(),
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(_selectedUser!.fullName),
                                subtitle: Text('DNI: ${_selectedUser!.dni}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _selectedUser = null;
                                      _dniController.clear();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Selector de tipo de vehículo
                  DropdownButtonFormField<VehicleTypeModel>(
                    value: _selectedVehicleType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Vehículo',
                      prefixIcon: Icon(Icons.directions_car),
                      border: OutlineInputBorder(),
                    ),
                    items: widget.catalogController.vehicleTypes
                        .map((vt) => DropdownMenuItem(
                              value: vt,
                              child: Text(vt.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVehicleType = value;
                        _selectedWashedType = null; // Reset lavado
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un tipo de vehículo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Selector de tipo de lavado
                  DropdownButtonFormField<WashedTypeModel>(
                    value: _selectedWashedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Lavado',
                      prefixIcon: Icon(Icons.local_car_wash),
                      border: OutlineInputBorder(),
                    ),
                    items: _selectedVehicleType == null
                        ? []
                        : widget.catalogController
                            .getWashedTypesByVehicle(_selectedVehicleType!.id)
                            .map((wt) => DropdownMenuItem(
                                  value: wt,
                                  child: Text('${wt.name} - ${wt.formattedPrice}'),
                                ))
                            .toList(),
                    onChanged: _selectedVehicleType == null
                        ? null
                        : (value) {
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
                  ),
                  const SizedBox(height: 16),
                  
                  // Selector de fecha
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de la Cita',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedDate == null
                            ? 'Seleccionar fecha'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selector de hora
                  InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora de la Cita',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedTime == null
                            ? 'Seleccionar hora'
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selector de estado de pago (solo admin)
                  if (widget.isAdmin)
                    DropdownButtonFormField<AppointmentStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Estado de Pago',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(),
                      ),
                      items: AppointmentStatus.values
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Row(
                                  children: [
                                    Icon(
                                      status == AppointmentStatus.PAYMENT
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      color: status == AppointmentStatus.PAYMENT
                                          ? Colors.green
                                          : Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
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
                  const SizedBox(height: 32),
                  
                  // Botón de envío
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditing ? 'Actualizar Cita' : 'Crear Cita',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
