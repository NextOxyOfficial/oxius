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
      Navigator.of(context).pop();
    }
  }

  bool get _isSubmitDisabled {
    return !_allOverBangladesh && 
           (_selectedState == null || _selectedCity == null || _selectedUpazila == null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Location',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Choose your location for relevant content',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // All Bangladesh Checkbox
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CheckboxListTile(
                        value: _allOverBangladesh,
                        onChanged: (value) {
                          setState(() {
                            _allOverBangladesh = value ?? false;
                            if (_allOverBangladesh) {
                              _selectedState = null;
                              _selectedCity = null;
                              _selectedUpazila = null;
                              _showErrors = false;
                            }
                          });
                        },
                        title: const Text(
                          'Show content from all over Bangladesh',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        activeColor: const Color(0xFF10B981),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    
                    // Form Fields
                    if (!_allOverBangladesh) ...[
                      // Division/State Dropdown
                      _buildFormField(
                        label: 'Division',
                        child: DropdownButtonFormField<String>(
                          value: _selectedState,
                          decoration: InputDecoration(
                            hintText: 'Select Division',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            errorText: _showErrors && _selectedState == null
                                ? 'Please select a division'
                                : null,
                          ),
                          items: _regions.map((region) {
                            return DropdownMenuItem(
                              value: region.nameEng,
                              child: Text(region.nameEng),
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
                      
                      const SizedBox(height: 16),
                      
                      // City Dropdown
                      _buildFormField(
                        label: 'City',
                        child: DropdownButtonFormField<String>(
                          value: _selectedCity,
                          decoration: InputDecoration(
                            hintText: 'Select City',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            errorText: _showErrors && _selectedCity == null && _selectedState != null
                                ? 'Please select a city'
                                : null,
                          ),
                          items: _cities.map((city) {
                            return DropdownMenuItem(
                              value: city.nameEng,
                              child: Text(city.nameEng),
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
                      
                      const SizedBox(height: 16),
                      
                      // Upazila/Area Dropdown
                      _buildFormField(
                        label: 'Area/Upazila',
                        child: DropdownButtonFormField<String>(
                          value: _selectedUpazila,
                          decoration: InputDecoration(
                            hintText: 'Select Area/Upazila',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            errorText: _showErrors && _selectedUpazila == null && _selectedCity != null
                                ? 'Please select an area'
                                : null,
                          ),
                          items: _upazilas.map((upazila) {
                            return DropdownMenuItem(
                              value: upazila.nameEng,
                              child: Text(upazila.nameEng),
                            );
                          }).toList(),
                          onChanged: _selectedCity == null
                              ? null
                              : (value) {
                                  setState(() => _selectedUpazila = value);
                                },
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitDisabled && !_isLoading
                            ? null
                            : _validateAndSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Set Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
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
