import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import '../models/appointment_model.dart';

/// Widget de tarjeta para mostrar una cita con diseno profesional.
class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isAdmin;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final Function(AppointmentStatus)? onStatusChange;
  final VoidCallback? onPrintInvoice;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    this.isAdmin = false,
    this.onTap,
    this.onEdit,
    this.onStatusChange,
    this.onPrintInvoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isPaid = appointment.isPaid;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
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
              _buildHeader(context, colorScheme, theme, isPaid),
              const SizedBox(height: AppSpacing.spacing16),
              _buildDateTimeRow(context, colorScheme, theme),
              if (appointment.washedTypePrice != null) ...[
                const SizedBox(height: AppSpacing.spacing12),
                _buildPriceRow(context, colorScheme, theme),
              ],
              if (isAdmin && appointment.userName != null) ...[
                const SizedBox(height: AppSpacing.spacing12),
                _buildClientRow(context, colorScheme, theme),
              ],
              if (isAdmin) ...[
                const SizedBox(height: AppSpacing.spacing16),
                Divider(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                  height: 1,
                ),
                const SizedBox(height: AppSpacing.spacing16),
                _buildActionButtons(context, colorScheme, theme, isPaid),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ColorScheme colorScheme, ThemeData theme, bool isPaid) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPaid
                  ? [Colors.green[400]!, Colors.green[600]!]
                  : [Colors.orange[400]!, Colors.orange[600]!],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color:
                    (isPaid ? Colors.green : Colors.orange).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
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
                appointment.washedTypeName ?? 'Lavado',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (appointment.vehicleTypeName != null) ...[
                const SizedBox(height: 2),
                Text(
                  appointment.vehicleTypeName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                (isPaid ? Colors.green : Colors.orange).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  (isPaid ? Colors.green[600] : Colors.orange[600])!,
              width: 1.5,
            ),
          ),
          child: Text(
            appointment.status.displayName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isPaid ? Colors.green[700] : Colors.orange[700],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoChip(
            icon: Icons.calendar_today_rounded,
            label: appointment.formattedDate,
            colorScheme: colorScheme,
            theme: theme,
          ),
        ),
        const SizedBox(width: AppSpacing.spacing8),
        Expanded(
          child: _buildInfoChip(
            icon: Icons.access_time_rounded,
            label: appointment.appointmentTime,
            colorScheme: colorScheme,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.spacing8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_money_rounded,
            size: 18,
            color: Colors.green[700],
          ),
          const SizedBox(width: AppSpacing.spacing8),
          Text(
            appointment.formattedPrice!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientRow(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_rounded,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.spacing8),
          Text(
            appointment.userName!,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, ColorScheme colorScheme, ThemeData theme, bool isPaid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (onStatusChange != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final newStatus = isPaid
                        ? AppointmentStatus.UNPAYMENT
                        : AppointmentStatus.PAYMENT;
                    onStatusChange!(newStatus);
                  },
                  icon: Icon(
                    isPaid
                        ? Icons.cancel_rounded
                        : Icons.check_circle_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isPaid ? 'Sin Pagar' : 'Pagado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isPaid ? Colors.orange[700] : Colors.green[700],
                    side: BorderSide(
                      color: (isPaid
                              ? Colors.orange[300]
                              : Colors.green[300])!,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacing16,
                        vertical: AppSpacing.spacing12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (onStatusChange != null && onEdit != null)
              const SizedBox(width: AppSpacing.spacing8),
            if (onEdit != null)
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(
                    'Editar',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacing16,
                        vertical: AppSpacing.spacing12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (isPaid && onPrintInvoice != null) ...[
          const SizedBox(height: AppSpacing.spacing8),
          FilledButton.icon(
            onPressed: onPrintInvoice,
            icon: const Icon(Icons.print_rounded, size: 18),
            label: Text(
              'Imprimir Factura',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing16,
                  vertical: AppSpacing.spacing12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
