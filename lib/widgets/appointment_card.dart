import 'package:flutter/material.dart';
import '../models/appointment_model.dart';

/// Widget de tarjeta para mostrar una cita.
class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isAdmin;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final Function(AppointmentStatus)? onStatusChange;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    this.isAdmin = false,
    this.onTap,
    this.onEdit,
    this.onStatusChange,
  }) : super(key: key);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appointment.isPaid ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      appointment.isPaid ? Icons.check_circle : Icons.schedule,
                      color: appointment.isPaid ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.washedTypeName ?? 'Lavado',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (appointment.vehicleTypeName != null)
                          Text(
                            appointment.vehicleTypeName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      appointment.status.displayName,
                      style: TextStyle(
                        color: appointment.isPaid ? Colors.green[700] : Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor:
                        appointment.isPaid ? Colors.green[50] : Colors.orange[50],
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    appointment.formattedDate,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    appointment.appointmentTime,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (appointment.washedTypePrice != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      appointment.formattedPrice!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                    ),
                  ],
                ),
              ],
              if (isAdmin && appointment.userName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      appointment.userName!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              // Botones de acción para admin
              if (isAdmin) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onStatusChange != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          final newStatus = appointment.isPaid
                              ? AppointmentStatus.UNPAYMENT
                              : AppointmentStatus.PAYMENT;
                          onStatusChange!(newStatus);
                        },
                        icon: Icon(
                          appointment.isPaid ? Icons.remove_circle : Icons.check_circle,
                          size: 18,
                        ),
                        label: Text(
                          appointment.isPaid ? 'Marcar sin pagar' : 'Marcar pagado',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: appointment.isPaid ? Colors.orange : Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    if (onEdit != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text(
                          'Editar',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
