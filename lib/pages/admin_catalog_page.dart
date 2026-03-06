import 'package:flutter/material.dart';
import '../controllers/catalog_controller.dart';
import '../models/vehicle_type_model.dart';
import '../models/washed_type_model.dart';
import '../utils/validators.dart';

/// Página de administración para gestionar tipos de vehículos y lavados.
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Tipo de Vehículo'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Sedan, SUV, Camioneta',
              border: OutlineInputBorder(),
            ),
            validator: (value) => AppointmentValidators.required(
              value,
              fieldName: 'El nombre',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final result = await widget.catalogController.createVehicleType(
                nameController.text.trim(),
              );

              if (!mounted) return;
              Navigator.pop(context);

              if (result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tipo de vehículo creado'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.catalogController.errorMessage ??
                          'Error al crear',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showCreateWashedTypeDialog() {
    // Validar que haya tipos de vehículos primero
    if (widget.catalogController.vehicleTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes crear tipos de vehículos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    VehicleTypeModel? selectedVehicle;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Tipo de Lavado'),
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
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Vehículo',
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
                          selectedVehicle = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona un tipo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Lavado',
                        hintText: 'Ej: Lavado Básico, Premium',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => AppointmentValidators.required(
                        value,
                        fieldName: 'El nombre',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        hintText: '0.00',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
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
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final result = await widget.catalogController.createWashedType(
                name: nameController.text.trim(),
                vehicleTypeId: selectedVehicle!.id,
                price: double.parse(priceController.text.trim()),
              );

              if (!mounted) return;
              Navigator.pop(context);

              if (result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tipo de lavado creado'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.catalogController.errorMessage ??
                          'Error al crear',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Catálogo'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tipos de Vehículo'),
            Tab(text: 'Tipos de Lavado'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.catalogController,
        builder: (context, child) {
          if (widget.catalogController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildVehicleTypesList(),
              _buildWashedTypesList(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showCreateVehicleTypeDialog();
          } else {
            // Validar que haya tipos de vehículos antes de crear lavados
            if (widget.catalogController.vehicleTypes.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Primero debes crear tipos de vehículos'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
              // Cambiar a la pestaña de vehículos
              _tabController.animateTo(0);
            } else {
              _showCreateWashedTypeDialog();
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVehicleTypesList() {
    final vehicleTypes = widget.catalogController.vehicleTypes;

    if (vehicleTypes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay tipos de vehículos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea el primer tipo de vehículo usando el botón +',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicleTypes.length,
      itemBuilder: (context, index) {
        final vehicleType = vehicleTypes[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.directions_car),
            title: Text(vehicleType.name),
            subtitle: Text('ID: ${vehicleType.id}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Implementar edición
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWashedTypesList() {
    final washedTypes = widget.catalogController.washedTypes;

    if (washedTypes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_car_wash_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay tipos de lavado',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.catalogController.vehicleTypes.isEmpty
                  ? 'Primero debes crear tipos de vehículos'
                  : 'Crea el primer tipo de lavado usando el botón +',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: washedTypes.length,
      itemBuilder: (context, index) {
        final washedType = washedTypes[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.local_car_wash),
            title: Text(washedType.name),
            subtitle: Text(
              '${washedType.vehicleTypeName ?? 'N/A'} - ${washedType.formattedPrice}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Implementar edición
              },
            ),
          ),
        );
      },
    );
  }
}
