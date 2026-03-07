import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_ui/core_ui.dart';
import '../models/appointment_model.dart';

/// Tarjeta de cita estilo iOS — limpia, sin sombras, colores del sistema.
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
    final theme = Theme.of(context);
    final isPaid = appointment.isPaid;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        decoration: BoxDecoration(
          color: AppColors.secondarySystemBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon + title + status badge
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPaid ? AppColors.systemGreen : AppColors.systemOrange,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Icon(
                    isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.washedTypeName ?? 'Lavado',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (appointment.vehicleTypeName != null)
                        Text(
                          appointment.vehicleTypeName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPaid ? AppColors.systemGreen : AppColors.systemOrange)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    appointment.status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isPaid ? AppColors.systemGreen : AppColors.systemOrange,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.spacing12),

            // Date + Time row
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.secondaryLabel),
                const SizedBox(width: AppSpacing.spacing6),
                Text(
                  appointment.formattedDate,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryLabel,
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing16),
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.secondaryLabel),
                const SizedBox(width: AppSpacing.spacing6),
                Text(
                  appointment.appointmentTime,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryLabel,
                  ),
                ),
                const Spacer(),
                if (appointment.washedTypePrice != null)
                  Text(
                    appointment.formattedPrice!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.label,
                    ),
                  ),
              ],
            ),

            // Admin: client name
            if (isAdmin && appointment.userName != null) ...[
              const SizedBox(height: AppSpacing.spacing8),
              Row(
                children: [
                  const Icon(Icons.person_rounded,
                      size: 14, color: AppColors.secondaryLabel),
                  const SizedBox(width: AppSpacing.spacing6),
                  Text(
                    appointment.userName!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ],

            // Admin actions
            if (isAdmin) ...[
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.spacing12),
                child: Divider(
                  color: AppColors.separator,
                  height: 0.5,
                  thickness: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing12),
              _buildActionButtons(context, theme, isPaid),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, bool isPaid) {
    return Row(
      children: [
        if (onStatusChange != null)
          Expanded(
            child: _buildActionBtn(
              icon: isPaid ? Icons.cancel_rounded : Icons.check_circle_rounded,
              label: isPaid ? 'Sin Pagar' : 'Pagado',
              color: isPaid ? AppColors.systemOrange : AppColors.systemGreen,
              onTap: () {
                final newStatus = isPaid
                    ? AppointmentStatus.UNPAYMENT
                    : AppointmentStatus.PAYMENT;
                onStatusChange!(newStatus);
              },
            ),
          ),
        if (onStatusChange != null && onEdit != null)
          const SizedBox(width: AppSpacing.spacing8),
        if (onEdit != null)
          Expanded(
            child: _buildActionBtn(
              icon: Icons.edit_rounded,
              label: 'Editar',
              color: AppColors.primary,
              filled: true,
              onTap: onEdit!,
            ),
          ),
        if (isPaid && onPrintInvoice != null) ...[
          const SizedBox(width: AppSpacing.spacing8),
          Expanded(
            child: _buildActionBtn(
              icon: Icons.print_rounded,
              label: 'Factura',
              color: AppColors.systemBlue,
              filled: true,
              onTap: onPrintInvoice!,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing10),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: filled ? AppColors.white : color),
            const SizedBox(width: AppSpacing.spacing6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: filled ? AppColors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
