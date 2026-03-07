import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_ui/core_ui.dart';
import '../controllers/appointment_controller.dart';
import '../controllers/catalog_controller.dart';
import '../models/appointment_model.dart';
import '../widgets/appointment_card.dart';
import 'appointment_form_page.dart';

/// Pagina que muestra el listado de citas del usuario.
class AppointmentListPage extends StatefulWidget {
  final AppointmentController controller;
  final CatalogController? catalogController;
  final bool isAdmin;
  final Function(AppointmentModel)? onPrintInvoice;

  const AppointmentListPage({
    Key? key,
    required this.controller,
    this.catalogController,
    this.isAdmin = false,
    this.onPrintInvoice,
  }) : super(key: key);

  @override
  State<AppointmentListPage> createState() => _AppointmentListPageState();
}

class _AppointmentListPageState extends State<AppointmentListPage> {
  AppointmentStatus? _filterStatus;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (widget.isAdmin) {
      final firstDay =
          DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final lastDay = DateTime(
          _selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
      await widget.controller.filterByDateRange(
        startDate: firstDay,
        endDate: lastDay,
      );
    } else {
      await widget.controller.loadUserAppointments();
    }
  }

  Future<void> _changeMonth(int monthsToAdd) async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + monthsToAdd,
      );
    });
    await _loadAppointments();
  }

  String _getMonthYearText() {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  Future<void> _filterByStatus(AppointmentStatus? status) async {
    setState(() {
      _filterStatus = status;
    });

    if (status == null) {
      await _loadAppointments();
    } else {
      await widget.controller
          .filterByStatus(status, isAdmin: widget.isAdmin);
    }
  }

  Future<void> _editAppointment(AppointmentModel appointment) async {
    if (widget.catalogController == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentFormPage(
          appointmentController: widget.controller,
          catalogController: widget.catalogController!,
          isAdmin: widget.isAdmin,
          appointment: appointment,
        ),
      ),
    );

    if (result == true) {
      await _loadAppointments();
    }
  }

  Future<void> _changeAppointmentStatus(
    AppointmentModel appointment,
    AppointmentStatus newStatus,
  ) async {
    final confirmed = await CUAlertDialog(
      title: 'Cambiar Estado',
      message: 'Se cambiara el estado a "${newStatus.displayName}"',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      onConfirm: () {},
      onCancel: () {},
    ).show(context);

    if (confirmed != true) return;

    final result = await widget.controller.updateAppointment(
      id: appointment.id,
      status: newStatus,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result != null
            ? 'Estado actualizado'
            : 'Error al actualizar'),
        backgroundColor:
            result != null ? AppColors.systemGreen : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildFilterChips()),
          if (widget.isAdmin && _buildAdminMonthSelector() != null)
            SliverToBoxAdapter(child: _buildAdminMonthSelector()!),
          _buildBody(),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.spacing48),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.systemBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        widget.isAdmin ? 'Todas las Citas' : 'Mis Citas',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.label,
          letterSpacing: -0.4,
        ),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Center(
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSpacing.spacing12),
      child: Row(
        children: [
          _buildChip(
            label: 'Todas',
            isSelected: _filterStatus == null,
            onTap: () => _filterByStatus(null),
          ),
          const SizedBox(width: AppSpacing.spacing8),
          _buildChip(
            label: 'Pendientes',
            isSelected: _filterStatus == AppointmentStatus.UNPAYMENT,
            onTap: () => _filterByStatus(AppointmentStatus.UNPAYMENT),
          ),
          const SizedBox(width: AppSpacing.spacing8),
          _buildChip(
            label: 'Pagadas',
            isSelected: _filterStatus == AppointmentStatus.PAYMENT,
            onTap: () => _filterByStatus(AppointmentStatus.PAYMENT),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.secondarySystemBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.secondaryLabel,
          ),
        ),
      ),
    );
  }

  Widget? _buildAdminMonthSelector() {
    if (!widget.isAdmin) return null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSpacing.spacing12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _changeMonth(-1),
            child: const Icon(Icons.chevron_left_rounded,
                color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.spacing12),
          Text(
            _getMonthYearText(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.label,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing12),
          GestureDetector(
            onTap: () => _changeMonth(1),
            child: const Icon(Icons.chevron_right_rounded,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SliverToBoxAdapter(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          if (widget.controller.isLoading) {
            return const SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            );
          }

          if (widget.controller.status == AppointmentListStatus.error) {
            return _buildEmptyOrError(
              icon: Icons.error_outline_rounded,
              title: 'Error al cargar',
              subtitle: widget.controller.errorMessage ?? 'Error desconocido',
              showRetry: true,
            );
          }

          if (widget.controller.isEmpty) {
            return _buildEmptyOrError(
              icon: Icons.event_busy_rounded,
              title: _filterStatus == null ? 'No hay citas' : 'Sin resultados',
              subtitle: _filterStatus == null
                  ? 'Aun no tienes citas agendadas'
                  : 'No hay citas con este filtro',
            );
          }

          return _buildList();
        },
      ),
    );
  }

  Widget _buildEmptyOrError({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showRetry = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: AppSpacing.spacing48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.systemGray5,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Icon(icon, size: 32, color: AppColors.systemGray),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.secondaryLabel,
            ),
            textAlign: TextAlign.center,
          ),
          if (showRetry) ...[
            const SizedBox(height: AppSpacing.spacing20),
            GestureDetector(
              onTap: _loadAppointments,
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: widget.controller.appointments.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.spacing10),
      itemBuilder: (context, index) {
        final appointment = widget.controller.appointments[index];
        return AppointmentCard(
          appointment: appointment,
          isAdmin: widget.isAdmin,
          onTap: () {},
          onEdit: widget.isAdmin && widget.catalogController != null
              ? () => _editAppointment(appointment)
              : null,
          onStatusChange: widget.isAdmin
              ? (newStatus) =>
                  _changeAppointmentStatus(appointment, newStatus)
              : null,
          onPrintInvoice: widget.isAdmin &&
                  appointment.isPaid &&
                  widget.onPrintInvoice != null
              ? () => widget.onPrintInvoice!(appointment)
              : null,
        );
      },
    );
  }
}
