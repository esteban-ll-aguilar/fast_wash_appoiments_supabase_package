import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import '../controllers/catalog_controller.dart';
import '../models/vehicle_type_model.dart';
import '../models/washed_type_model.dart';
import '../utils/validators.dart';

/// Pagina de administracion para gestionar tipos de vehiculos y lavados.
class AdminCatalogPage extends StatefulWidget {
  final CatalogController catalogController;

  const AdminCatalogPage({
    Key? key,
    required this.catalogController,
  }) : super(key: key);

  @override
  State<AdminCatalogPage> createState() => _AdminCatalogPageState();
}

class _AdminCatalogPageState extends State<AdminCatalogPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    await widget.catalogController.loadCatalog();
  }

  void _showCreateVehicleTypeDialog() {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.directions_car_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing12),
            Text(
              'Nuevo Tipo de Vehiculo',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CUTextField(
                controller: nameController,
                labelText: 'Nombre',
                hintText: 'Ej: Sedan, SUV, Camioneta',
                prefixIcon: const Icon(Icons.edit_rounded),
                textCapitalization: TextCapitalization.words,
                validator: (value) => AppointmentValidators.required(
                  value,
                  fieldName: 'El nombre',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final result =
                  await widget.catalogController.createVehicleType(
                nameController.text.trim(),
              );

              if (!mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        result != null
                            ? Icons.check_circle
                            : Icons.error,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSpacing.spacing12),
                      Text(result != null
                          ? 'Tipo de vehiculo creado'
                          : widget.catalogController.errorMessage ??
                              'Error al crear'),
                    ],
                  ),
                  backgroundColor: result != null
                      ? Colors.green[700]
                      : Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showCreateWashedTypeDialog() {
    if (widget.catalogController.vehicleTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: AppSpacing.spacing12),
              Expanded(
                child: Text('Primero debes crear tipos de vehiculos'),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    VehicleTypeModel? selectedVehicle;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
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
            Flexible(
              child: Text(
                'Nuevo Tipo de Lavado',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CUDropdownField<VehicleTypeModel>(
                      value: selectedVehicle,
                      labelText: 'Tipo de Vehiculo',
                      prefixIcon:
                          const Icon(Icons.directions_car_rounded),
                      items: widget.catalogController.vehicleTypes
                          .map((vt) => DropdownMenuItem(
                                value: vt,
                                child: Text(vt.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedVehicle = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Selecciona un tipo';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.spacing16),
                    CUTextField(
                      controller: nameController,
                      labelText: 'Nombre del Lavado',
                      hintText: 'Ej: Lavado Basico, Premium',
                      prefixIcon: const Icon(Icons.edit_rounded),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) =>
                          AppointmentValidators.required(
                        value,
                        fieldName: 'El nombre',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing16),
                    CUTextField(
                      controller: priceController,
                      labelText: 'Precio',
                      hintText: '0.00',
                      prefixIcon:
                          const Icon(Icons.attach_money_rounded),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: AppointmentValidators.positiveNumber,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final result =
                  await widget.catalogController.createWashedType(
                name: nameController.text.trim(),
                vehicleTypeId: selectedVehicle!.id,
                price: double.parse(priceController.text.trim()),
              );

              if (!mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        result != null
                            ? Icons.check_circle
                            : Icons.error,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSpacing.spacing12),
                      Text(result != null
                          ? 'Tipo de lavado creado'
                          : widget.catalogController.errorMessage ??
                              'Error al crear'),
                    ],
                  ),
                  backgroundColor: result != null
                      ? Colors.green[700]
                      : Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
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
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 56, bottom: 52),
              title: Text(
                'Administrar Catalogo',
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: colorScheme.onPrimary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Vehiculos'),
                    Tab(text: 'Lavados'),
                  ],
                ),
              ),
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
                            'Cargando catalogo...',
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
                  maxWidth: 800,
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).size.height - 250,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildVehicleTypesList(theme),
                        _buildWashedTypesList(theme),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return FloatingActionButton.extended(
            onPressed: () {
              if (_tabController.index == 0) {
                _showCreateVehicleTypeDialog();
              } else {
                if (widget.catalogController.vehicleTypes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.warning_rounded,
                              color: Colors.white),
                          SizedBox(width: AppSpacing.spacing12),
                          Expanded(
                            child: Text(
                                'Primero crea tipos de vehiculos'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.orange[700],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  _tabController.animateTo(0);
                } else {
                  _showCreateWashedTypeDialog();
                }
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(
              _tabController.index == 0 ? 'Vehiculo' : 'Lavado',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVehicleTypesList(ThemeData theme) {
    final vehicleTypes = widget.catalogController.vehicleTypes;
    final colorScheme = theme.colorScheme;

    if (vehicleTypes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.spacing24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 64,
                  color:
                      colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing24),
              Text(
                'No hay tipos de vehiculos',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                'Crea el primer tipo usando el boton inferior',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      itemCount: vehicleTypes.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.spacing12),
      itemBuilder: (context, index) {
        final vehicleType = vehicleTypes[index];
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
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer
                            .withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleType.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${vehicleType.id}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: Text(
                    'Activo',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWashedTypesList(ThemeData theme) {
    final washedTypes = widget.catalogController.washedTypes;
    final colorScheme = theme.colorScheme;

    if (washedTypes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.spacing24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_car_wash_outlined,
                  size: 64,
                  color:
                      colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing24),
              Text(
                'No hay tipos de lavado',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                widget.catalogController.vehicleTypes.isEmpty
                    ? 'Primero debes crear tipos de vehiculos'
                    : 'Crea el primer tipo usando el boton inferior',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      itemCount: washedTypes.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.spacing12),
      itemBuilder: (context, index) {
        final washedType = washedTypes[index];
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
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.secondaryContainer,
                            colorScheme.secondaryContainer
                                .withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_car_wash_rounded,
                        color: colorScheme.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            washedType.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            washedType.vehicleTypeName ?? 'N/A',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                              color:
                                  colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.green[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money_rounded,
                            size: 16,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            washedType.formattedPrice,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
