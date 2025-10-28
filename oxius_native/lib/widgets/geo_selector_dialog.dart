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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header - Compact Professional Design
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Location',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose your area to see relevant ads',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content - 4px side padding
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // All Bangladesh Checkbox - Compact
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: _allOverBangladesh 
                                ? const Color(0xFF10B981).withOpacity(0.08)
                                : const Color(0xFFF9FAFB),
                            border: Border.all(
                              color: _allOverBangladesh 
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
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
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: _allOverBangladesh
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'All over Bangladesh',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                    letterSpacing: -0.1,
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
                      // Info text - Compact
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCD34D), width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB45309)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Select your location to see relevant ads',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Division/State Dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildFormField(
                        label: 'Division',
                        icon: Icons.map_outlined,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _showErrors && _selectedState == null
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _regions.any((r) => r.nameEng == _selectedState) ? _selectedState : null,
                            decoration: const InputDecoration(
                              hintText: 'Choose division',
                              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280), size: 18),
                            items: _regions.map((region) {
                              return DropdownMenuItem(
                                value: region.nameEng,
                                child: Text(
                                  region.nameEng,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF111827),
                                    fontWeight: FontWeight.w500,
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
                      
                      const SizedBox(height: 14),
                      
                      // City Dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildFormField(
                        label: 'City / District',
                        icon: Icons.location_city_outlined,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedState == null 
                                ? const Color(0xFFF9FAFB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _showErrors && _selectedCity == null && _selectedState != null
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _cities.any((c) => c.nameEng == _selectedCity) ? _selectedCity : null,
                            decoration: const InputDecoration(
                              hintText: 'Choose city',
                              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280), size: 18),
                            items: _cities.map((city) {
                              return DropdownMenuItem(
                                value: city.nameEng,
                                child: Text(
                                  city.nameEng,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF111827),
                                    fontWeight: FontWeight.w500,
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
                      
                      const SizedBox(height: 14),
                      
                      // Upazila/Area Dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildFormField(
                        label: 'Area / Upazila',
                        icon: Icons.pin_drop_outlined,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedCity == null 
                                ? const Color(0xFFF9FAFB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _showErrors && _selectedUpazila == null && _selectedCity != null
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _upazilas.any((u) => u.nameEng == _selectedUpazila) ? _selectedUpazila : null,
                            decoration: const InputDecoration(
                              hintText: 'Choose area',
                              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280), size: 18),
                            items: _upazilas.map((upazila) {
                              return DropdownMenuItem(
                                value: upazila.nameEng,
                                child: Text(
                                  upazila.nameEng,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF111827),
                                    fontWeight: FontWeight.w500,
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
                    
                    const SizedBox(height: 18),
                    
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          // Cancel Button - Compact
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6B7280),
                                  side: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Submit Button - Compact
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: _isSubmitDisabled && !_isLoading
                                    ? null
                                    : _validateAndSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, size: 16),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _allOverBangladesh ? 'Continue' : 'Set Location',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.1,
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
                    
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
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
                size: 16,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
