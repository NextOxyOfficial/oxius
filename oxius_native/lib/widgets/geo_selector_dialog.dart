import 'package:flutter/material.dart';
import '../models/geo_location.dart';
import '../services/geo_location_service.dart';
import '../services/api_service.dart';

class GeoSelectorDialog extends StatefulWidget {
  final GeoLocation? initialLocation;
  final Function(GeoLocation) onLocationSelected;

  const GeoSelectorDialog({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<GeoSelectorDialog> createState() => _GeoSelectorDialogState();
}

class _GeoSelectorDialogState extends State<GeoSelectorDialog> {
  late final GeoLocationService _geoService;
  
  bool _isLoading = false;
  bool _showErrors = false;
  bool _allOverBangladesh = false;
  
  String? _selectedState;
  String? _selectedCity;
  String? _selectedUpazila;
  
  List<Region> _regions = [];
  List<City> _cities = [];
  List<Upazila> _upazilas = [];

  @override
  void initState() {
    super.initState();
    _geoService = GeoLocationService(baseUrl: ApiService.baseUrl);
    
    // Initialize with existing location if provided
    if (widget.initialLocation != null) {
      _allOverBangladesh = widget.initialLocation!.allOverBangladesh;
      _selectedState = widget.initialLocation!.state;
      _selectedCity = widget.initialLocation!.city;
      _selectedUpazila = widget.initialLocation!.upazila;
    }
    
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    setState(() => _isLoading = true);
    try {
      final regions = await _geoService.fetchRegions();
      setState(() {
        _regions = regions;
        _isLoading = false;
      });
      
      // Load cities if state is already selected
      if (_selectedState != null) {
        await _loadCities(_selectedState!);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load regions: $e')),
        );
      }
    }
  }

  Future<void> _loadCities(String stateName) async {
    setState(() => _isLoading = true);
    try {
      final cities = await _geoService.fetchCities(regionName: stateName);
      setState(() {
        _cities = cities;
        _isLoading = false;
      });
      
      // Load upazilas if city is already selected
      if (_selectedCity != null) {
        await _loadUpazilas(_selectedCity!);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cities: $e')),
        );
      }
    }
  }

  Future<void> _loadUpazilas(String cityName) async {
    setState(() => _isLoading = true);
    try {
      final upazilas = await _geoService.fetchUpazilas(cityName: cityName);
      setState(() {
        _upazilas = upazilas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load areas: $e')),
        );
      }
    }
  }

  void _validateAndSubmit() {
    setState(() => _showErrors = true);
    
    if (_allOverBangladesh || 
        (_selectedState != null && _selectedCity != null && _selectedUpazila != null)) {
      final location = GeoLocation(
        country: 'Bangladesh',
        state: _allOverBangladesh ? null : _selectedState,
        city: _allOverBangladesh ? null : _selectedCity,
        upazila: _allOverBangladesh ? null : _selectedUpazila,
        allOverBangladesh: _allOverBangladesh,
      );
      
      widget.onLocationSelected(location);
      Navigator.of(context).pop(location);
    }
  }

  bool get _isSubmitDisabled {
    return !_allOverBangladesh && 
           (_selectedState == null || _selectedCity == null || _selectedUpazila == null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: SizedBox(
        width: double.maxFinite,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF059669),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Your Location',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Find ads relevant to your area',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // All Bangladesh Checkbox
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _allOverBangladesh = !_allOverBangladesh;
                            if (_allOverBangladesh) {
                              _selectedState = null;
                              _selectedCity = null;
                              _selectedUpazila = null;
                              _showErrors = false;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: _allOverBangladesh 
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : const Color(0xFFF9FAFB),
                          border: Border.all(
                            color: _allOverBangladesh 
                                ? const Color(0xFF10B981)
                                : const Color(0xFFE5E7EB),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _allOverBangladesh 
                                    ? const Color(0xFF10B981)
                                    : Colors.white,
                                border: Border.all(
                                  color: _allOverBangladesh 
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFD1D5DB),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: _allOverBangladesh
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'All over Bangladesh',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                    
                    // Form Fields
                    if (!_allOverBangladesh) ...[
                      // Info text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: Color(0xFFB45309)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select your specific location to see relevant ads',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB45309),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                      
                      // Division/State Dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildFormField(
                        label: 'Division',
                        icon: Icons.map_outlined,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _showErrors && _selectedState == null
                                  ? Colors.red
                                  : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedState,
                            decoration: const InputDecoration(
                              hintText: 'Choose your division',
                              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                            items: _regions.map((region) {
                              return DropdownMenuItem(
                                value: region.nameEng,
                                child: Text(
                                  region.nameEng,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedState = value;
                                _selectedCity = null;
                                _selectedUpazila = null;
                                _cities = [];
                                _upazilas = [];
                              });
                              if (value != null) {
                                _loadCities(value);
                              }
                            },
                          ),
                        ),
                      ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // City Dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildFormField(
                        label: 'City / District',
                        icon: Icons.location_city_outlined,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedState == null 
                                ? const Color(0xFFF9FAFB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _showErrors && _selectedCity == null && _selectedState != null
                                  ? Colors.red
                                  : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCity,
                            decoration: const InputDecoration(
                              hintText: 'Choose your city',
                              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                            items: _cities.map((city) {
                              return DropdownMenuItem(
                                value: city.nameEng,
                                child: Text(
                                  city.nameEng,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _selectedState == null
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedCity = value;
                                      _selectedUpazila = null;
                                      _upazilas = [];
                                    });
                                    if (value != null) {
                                      _loadUpazilas(value);
                                    }
                                  },
                          ),
                        ),
                      ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Upazila/Area Dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildFormField(
                        label: 'Area / Upazila',
                        icon: Icons.pin_drop_outlined,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedCity == null 
                                ? const Color(0xFFF9FAFB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _showErrors && _selectedUpazila == null && _selectedCity != null
                                  ? Colors.red
                                  : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedUpazila,
                            decoration: const InputDecoration(
                              hintText: 'Choose your area',
                              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                            items: _upazilas.map((upazila) {
                              return DropdownMenuItem(
                                value: upazila.nameEng,
                                child: Text(
                                  upazila.nameEng,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _selectedCity == null
                                ? null
                                : (value) {
                                    setState(() => _selectedUpazila = value);
                                  },
                          ),
                        ),
                      ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6B7280),
                                  side: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Submit Button
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: _isSubmitDisabled && !_isLoading
                                    ? null
                                    : _validateAndSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_outline, size: 18),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _allOverBangladesh ? 'Continue' : 'Set Location',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
