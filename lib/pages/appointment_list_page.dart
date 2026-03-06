import 'package:flutter/material.dart';
import '../controllers/appointment_controller.dart';
import '../models/appointment_model.dart';
import '../widgets/appointment_card.dart';

/// Página que muestra el listado de citas del usuario.
class AppointmentListPage extends StatefulWidget {
  final AppointmentController controller;
  final bool isAdmin;

  const AppointmentListPage({
    Key? key,
    required this.controller,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<AppointmentListPage> createState() => _AppointmentListPageState();
}

class _AppointmentListPageState extends State<AppointmentListPage> {
  AppointmentStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (widget.isAdmin) {
      await widget.controller.loadAllAppointments();
    } else {
      await widget.controller.loadUserAppointments();
    }
  }

  Future<void> _filterByStatus(AppointmentStatus? status) async {
    setState(() {
      _filterStatus = status;
    });

    if (status == null) {
      await _loadAppointments();
    } else {
      await widget.controller.filterByStatus(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        centerTitle: true,
        actions: [
          PopupMenuButton<AppointmentStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: _filterByStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todas'),
              ),
              const PopupMenuItem(
                value: AppointmentStatus.UNPAYMENT,
                child: Text('Pendientes de Pago'),
              ),
              const PopupMenuItem(
                value: AppointmentStatus.PAYMENT,
                child: Text('Pagadas'),
              ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          if (widget.controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (widget.controller.status == AppointmentListStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar las citas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.controller.errorMessage ?? 'Error desconocido',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadAppointments,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (widget.controller.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterStatus == null
                        ? 'No tienes citas agendadas'
                        : 'No hay citas con este filtro',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu primera cita usando el botón +',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadAppointments,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.controller.appointments.length,
              itemBuilder: (context, index) {
                final appointment = widget.controller.appointments[index];
                return AppointmentCard(
                  appointment: appointment,
                  isAdmin: widget.isAdmin,
                  onTap: () {
                    // Navegar a detalle de cita (opcional)
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
