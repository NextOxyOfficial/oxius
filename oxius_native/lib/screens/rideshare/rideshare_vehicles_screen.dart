import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/rideshare_models.dart';
import '../../services/rideshare_service.dart';

class RideshareVehiclesScreen extends StatefulWidget {
  const RideshareVehiclesScreen({super.key});

  @override
  State<RideshareVehiclesScreen> createState() => _RideshareVehiclesScreenState();
}

class _RideshareVehiclesScreenState extends State<RideshareVehiclesScreen> {
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await RideshareService.listVehicles();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _vehicles = result.data ?? [];
        } else {
          _error = result.message;
        }
      });
    }
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Vehicle',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete ${vehicle.displayName}?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await RideshareService.deleteVehicle(vehicle.id);
      if (mounted) {
        if (result.success) {
          _showSuccess('Vehicle deleted');
          _loadVehicles();
        } else {
          _showError(result.message);
        }
      }
    }
  }

  Future<void> _setAsDefault(Vehicle vehicle) async {
    final result = await RideshareService.updateVehicle(
      vehicle.id,
      isDefault: true,
    );
    
    if (mounted) {
      if (result.success) {
        _showSuccess('Default vehicle updated');
        _loadVehicles();
      } else {
        _showError(result.message);
      }
    }
  }

  void _showAddVehicleDialog() {
    _showVehicleDialog();
  }

  void _showEditVehicleDialog(Vehicle vehicle) {
    _showVehicleDialog(vehicle: vehicle);
  }

  void _showVehicleDialog({Vehicle? vehicle}) {
    final isEditing = vehicle != null;
    final formKey = GlobalKey<FormState>();
    
    String vehicleType = vehicle?.vehicleType ?? 'bike';
    final brandController = TextEditingController(text: vehicle?.brand ?? '');
    final modelController = TextEditingController(text: vehicle?.modelName ?? '');
    final colorController = TextEditingController(text: vehicle?.color ?? '');
    final regController = TextEditingController(text: vehicle?.registrationNumber ?? '');
    int seatCapacity = vehicle?.seatCapacity ?? 1;
    bool isDefault = vehicle?.isDefault ?? false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEditing ? 'Edit Vehicle' : 'Add Vehicle',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle type selector
                  Text(
                    'Vehicle Type',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTypeOption(
                        type: 'bike',
                        icon: '🏍️',
                        label: 'Bike',
                        isSelected: vehicleType == 'bike',
                        onTap: () => setDialogState(() => vehicleType = 'bike'),
                      ),
                      const SizedBox(width: 8),
                      _buildTypeOption(
                        type: 'car',
                        icon: '🚗',
                        label: 'Car',
                        isSelected: vehicleType == 'car',
                        onTap: () => setDialogState(() => vehicleType = 'car'),
                      ),
                      const SizedBox(width: 8),
                      _buildTypeOption(
                        type: 'cng',
                        icon: '🛺',
                        label: 'CNG',
                        isSelected: vehicleType == 'cng',
                        onTap: () => setDialogState(() => vehicleType = 'cng'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Registration number
                  TextFormField(
                    controller: regController,
                    decoration: InputDecoration(
                      labelText: 'Registration Number *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Registration number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Brand
                  TextFormField(
                    controller: brandController,
                    decoration: InputDecoration(
                      labelText: 'Brand',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Model
                  TextFormField(
                    controller: modelController,
                    decoration: InputDecoration(
                      labelText: 'Model',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Color
                  TextFormField(
                    controller: colorController,
                    decoration: InputDecoration(
                      labelText: 'Color',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Seat capacity
                  Row(
                    children: [
                      Text(
                        'Seat Capacity:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: seatCapacity > 1
                            ? () => setDialogState(() => seatCapacity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$seatCapacity',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: seatCapacity < 10
                            ? () => setDialogState(() => seatCapacity++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  
                  // Set as default
                  CheckboxListTile(
                    value: isDefault,
                    onChanged: (value) => setDialogState(() => isDefault = value ?? false),
                    title: Text(
                      'Set as default vehicle',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      
                      setDialogState(() => isSubmitting = true);
                      
                      RideshareApiResult result;
                      if (isEditing) {
                        result = await RideshareService.updateVehicle(
                          vehicle.id,
                          vehicleType: vehicleType,
                          registrationNumber: regController.text,
                          brand: brandController.text,
                          modelName: modelController.text,
                          color: colorController.text,
                          seatCapacity: seatCapacity,
                          isDefault: isDefault,
                        );
                      } else {
                        result = await RideshareService.createVehicle(
                          vehicleType: vehicleType,
                          registrationNumber: regController.text,
                          brand: brandController.text,
                          modelName: modelController.text,
                          color: colorController.text,
                          seatCapacity: seatCapacity,
                          isDefault: isDefault,
                        );
                      }
                      
                      if (mounted) {
                        Navigator.pop(context);
                        if (result.success) {
                          _showSuccess(isEditing ? 'Vehicle updated' : 'Vehicle added');
                          _loadVehicles();
                        } else {
                          _showError(result.message);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String type,
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Vehicles',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF6366F1)),
            onPressed: _showAddVehicleDialog,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVehicleDialog,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Vehicle',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVehicles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No vehicles yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your first vehicle to start driving',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVehicles,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _vehicles.length,
        itemBuilder: (context, index) => _buildVehicleCard(_vehicles[index]),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: vehicle.isDefault 
              ? const Color(0xFF6366F1) 
              : const Color(0xFFE2E8F0),
          width: vehicle.isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    vehicle.vehicleIcon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.displayName.isNotEmpty 
                                  ? vehicle.displayName 
                                  : vehicle.registrationNumber,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (vehicle.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Default',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.registrationNumber,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      if (vehicle.color.isNotEmpty)
                        Text(
                          '${vehicle.color} • ${vehicle.seatCapacity} seats',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                if (!vehicle.isDefault)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _setAsDefault(vehicle),
                      icon: const Icon(Icons.star_outline_rounded, size: 16),
                      label: const Text('Set Default'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (!vehicle.isDefault) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditVehicleDialog(vehicle),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteVehicle(vehicle),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
