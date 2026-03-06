import 'package:flutter/material.dart';
import '../controllers/appointment_controller.dart';
import '../controllers/catalog_controller.dart';
import '../models/vehicle_type_model.dart';
import '../models/washed_type_model.dart';
import '../utils/validators.dart';

/// Página para crear o editar una cita.
class AppointmentFormPage extends StatefulWidget {
  final AppointmentController appointmentController;
  final CatalogController catalogController;

  const AppointmentFormPage({
    Key? key,
    required this.appointmentController,
    required this.catalogController,
  }) : super(key: key);

  @override
  State<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  VehicleTypeModel? _selectedVehicleType;
  WashedTypeModel? _selectedWashedType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    await widget.catalogController.loadCatalog();
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
    
    // Verificar disponibilidad
    final isAvailable = await widget.appointmentController.isTimeSlotAvailable(
      date: _selectedDate!,
      time: timeString,
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

    final appointment = await widget.appointmentController.createAppointment(
      washedTypeId: _selectedWashedType!.id,
      appointmentDate: _selectedDate!,
      appointmentTime: timeString,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (appointment != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.appointmentController.errorMessage ?? 'Error al crear la cita',
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
        title: const Text('Nueva Cita'),
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
                        : const Text(
                            'Crear Cita',
                            style: TextStyle(fontSize: 16),
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
