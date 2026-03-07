import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/appointment_controller.dart';
import '../controllers/catalog_controller.dart';
import '../models/appointment_model.dart';
import '../widgets/appointment_card.dart';
import 'appointment_form_page.dart';

/// Página que muestra el listado de citas del usuario.
class AppointmentListPage extends StatefulWidget {
  final AppointmentController controller;
  final CatalogController? catalogController;
  final bool isAdmin;
  final Function(AppointmentModel)? onPrintInvoice; // Callback para imprimir factura

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

class _AppointmentListPageState extends State<AppointmentListPage>
    with SingleTickerProviderStateMixin {
  AppointmentStatus? _filterStatus;
  DateTime _selectedMonth = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Spacing system
  static const double _spacing8 = 8.0;
  static const double _spacing12 = 12.0;
  static const double _spacing16 = 16.0;
  static const double _spacing24 = 24.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _loadAppointments();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    if (widget.isAdmin) {
      final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final lastDay =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
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
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
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
      await widget.controller.filterByStatus(status, isAdmin: widget.isAdmin);
    }
  }

  Future<void> _editAppointment(AppointmentModel appointment) async {
    if (widget.catalogController == null) return;

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AppointmentFormPage(
          appointmentController: widget.controller,
          catalogController: widget.catalogController!,
          isAdmin: widget.isAdmin,
          appointment: appointment,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
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
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.payment_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Cambiar Estado'),
          ],
        ),
        content: Text('Se cambiará el estado a "${newStatus.displayName}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await widget.controller.updateAppointment(
      id: appointment.id,
      status: newStatus,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result != null ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(result != null
                ? 'Estado actualizado exitosamente'
                : 'Error al actualizar'),
          ],
        ),
        backgroundColor: result != null ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colorScheme),
          SliverToBoxAdapter(child: _buildFilterChips(colorScheme)),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: widget.isAdmin ? 140 : 100,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: widget.isAdmin ? 56 : 16,
          bottom: 16,
        ),
        title: widget.isAdmin ? _buildAdminHeader() : _buildClientHeader(),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: widget.isAdmin ? _buildAdminActions() : null,
    );
  }

  Widget _buildAdminHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Todas las Citas',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getMonthYearText(),
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildClientHeader() {
    return Text(
      'Mis Citas',
      style: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  List<Widget> _buildAdminActions() {
    return [
      IconButton(
        icon: const Icon(Icons.chevron_left_rounded),
        tooltip: 'Mes anterior',
        onPressed: () => _changeMonth(-1),
        style: IconButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.chevron_right_rounded),
        tooltip: 'Mes siguiente',
        onPressed: () => _changeMonth(1),
        style: IconButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        ),
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildFilterChips(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_spacing16, _spacing8, _spacing16, _spacing16),
      child: Row(
        children: [
          Icon(
            Icons.filter_list_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: _spacing8),
          Text(
            'Filtrar:',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: _spacing8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Todas',
                    isSelected: _filterStatus == null,
                    onTap: () => _filterByStatus(null),
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: _spacing8),
                  _buildFilterChip(
                    label: 'Pendientes',
                    isSelected: _filterStatus == AppointmentStatus.UNPAYMENT,
                    onTap: () => _filterByStatus(AppointmentStatus.UNPAYMENT),
                    colorScheme: colorScheme,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: _spacing8),
                  _buildFilterChip(
                    label: 'Pagadas',
                    isSelected: _filterStatus == AppointmentStatus.PAYMENT,
                    onTap: () => _filterByStatus(AppointmentStatus.PAYMENT),
                    colorScheme: colorScheme,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    Color? color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (color ?? colorScheme.primary).withOpacity(0.15)
                  : colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? (color ?? colorScheme.primary)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (color ?? colorScheme.primary)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SliverToBoxAdapter(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          if (widget.controller.isLoading) {
            return _buildLoadingState();
          }

          if (widget.controller.status == AppointmentListStatus.error) {
            return _buildErrorState();
          }

          if (widget.controller.isEmpty) {
            return _buildEmptyState();
          }

          return _buildAppointmentsList();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: _spacing16),
            Text(
              'Cargando citas...',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(_spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(_spacing24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: _spacing16),
          Text(
            'Error al cargar',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: _spacing8),
          Text(
            widget.controller.errorMessage ?? 'Error desconocido',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _spacing24),
          FilledButton.icon(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(_spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(_spacing24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: _spacing24),
          Text(
            _filterStatus == null ? 'No hay citas' : 'Sin resultados',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: _spacing8),
          Text(
            _filterStatus == null
                ? 'Aún no tienes citas agendadas'
                : 'No hay citas con este filtro',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(_spacing16, 0, _spacing16, _spacing24),
          itemCount: widget.controller.appointments.length,
          separatorBuilder: (_, __) => const SizedBox(height: _spacing12),
          itemBuilder: (context, index) {
            final appointment = widget.controller.appointments[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: AppointmentCard(
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
              ),
            );
          },
        ),
      ),
    );
  }
}
