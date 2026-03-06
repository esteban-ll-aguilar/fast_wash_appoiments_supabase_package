import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/catalog_controller.dart';
import '../models/vehicle_type_model.dart';
import '../models/washed_type_model.dart';
import '../utils/validators.dart';

/// Página de administración para gestionar tipos de vehículos y lavados con diseño profesional.
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            const SizedBox(width: 12),
            Text(
              'Nuevo Tipo de Vehículo',
              style: GoogleFonts.dmSans(fontSize: 18),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: GoogleFonts.dmSans(),
                  hintText: 'Ej: Sedan, SUV, Camioneta',
                  hintStyle: GoogleFonts.dmSans(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  prefixIcon: const Icon(Icons.edit_rounded),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: GoogleFonts.dmSans(fontSize: 15),
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
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Cancelar', style: GoogleFonts.dmSans()),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final result = await widget.catalogController.createVehicleType(
                nameController.text.trim(),
              );

              if (!mounted) return;
              Navigator.pop(context);

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
                          ? 'Tipo de vehículo creado'
                          : widget.catalogController.errorMessage ??
                              'Error al crear'),
                    ],
                  ),
                  backgroundColor:
                      result != null ? Colors.green[700] : Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Crear', style: GoogleFonts.dmSans()),
          ),
        ],
      ),
    );
  }

  void _showCreateWashedTypeDialog() {
    if (widget.catalogController.vehicleTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Primero debes crear tipos de vehículos'),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    VehicleTypeModel? selectedVehicle;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Nuevo Tipo de Lavado',
                style: GoogleFonts.dmSans(fontSize: 18),
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
                    DropdownButtonFormField<VehicleTypeModel>(
                      value: selectedVehicle,
                      decoration: InputDecoration(
                        labelText: 'Tipo de Vehículo',
                        labelStyle: GoogleFonts.dmSans(),
                        prefixIcon: const Icon(Icons.directions_car_rounded),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                      dropdownColor: colorScheme.surface,
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Lavado',
                        labelStyle: GoogleFonts.dmSans(),
                        hintText: 'Ej: Lavado Básico, Premium',
                        hintStyle: GoogleFonts.dmSans(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        prefixIcon: const Icon(Icons.edit_rounded),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.dmSans(fontSize: 15),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => AppointmentValidators.required(
                        value,
                        fieldName: 'El nombre',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Precio',
                        labelStyle: GoogleFonts.dmSans(),
                        hintText: '0.00',
                        hintStyle: GoogleFonts.dmSans(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.dmSans(fontSize: 15),
                      keyboardType: const TextInputType.numberWithOptions(
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
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Cancelar', style: GoogleFonts.dmSans()),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final result = await widget.catalogController.createWashedType(
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
                        result != null ? Icons.check_circle : Icons.error,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(result != null
                          ? 'Tipo de lavado creado'
                          : widget.catalogController.errorMessage ??
                              'Error al crear'),
                    ],
                  ),
                  backgroundColor:
                      result != null ? Colors.green[700] : Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Crear', style: GoogleFonts.dmSans()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              titlePadding: const EdgeInsets.only(left: 56, bottom: 52),
              title: Text(
                'Administrar Catálogo',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
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
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  labelStyle: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Vehículos'),
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
                          const SizedBox(height: 16),
                          Text(
                            'Cargando catálogo...',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: MediaQuery.of(context).size.height - 250,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVehicleTypesList(),
                      _buildWashedTypesList(),
                    ],
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
                      content: Row(
                        children: [
                          const Icon(Icons.warning_rounded, color: Colors.white),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Primero crea tipos de vehículos'),
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
            icon: Icon(
              _tabController.index == 0
                  ? Icons.add_rounded
                  : Icons.add_rounded,
            ),
            label: Text(
              _tabController.index == 0 ? 'Vehículo' : 'Lavado',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVehicleTypesList() {
    final vehicleTypes = widget.catalogController.vehicleTypes;
    final colorScheme = Theme.of(context).colorScheme;

    if (vehicleTypes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No hay tipos de vehículos',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea el primer tipo usando el botón inferior',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
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
      padding: const EdgeInsets.all(20),
      itemCount: vehicleTypes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
            padding: const EdgeInsets.all(16),
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
                        colorScheme.primaryContainer.withOpacity(0.6),
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
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${vehicleType.id}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: Text(
                    'Activo',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
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

  Widget _buildWashedTypesList() {
    final washedTypes = widget.catalogController.washedTypes;
    final colorScheme = Theme.of(context).colorScheme;

    if (washedTypes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_car_wash_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No hay tipos de lavado',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.catalogController.vehicleTypes.isEmpty
                    ? 'Primero debes crear tipos de vehículos'
                    : 'Crea el primer tipo usando el botón inferior',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
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
      padding: const EdgeInsets.all(20),
      itemCount: washedTypes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
            padding: const EdgeInsets.all(16),
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
                            colorScheme.secondaryContainer.withOpacity(0.6),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            washedType.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            washedType.vehicleTypeName ?? 'N/A',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
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
                        border: Border.all(color: Colors.green[300]!),
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
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
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