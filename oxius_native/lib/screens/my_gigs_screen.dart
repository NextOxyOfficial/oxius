import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/user_state_service.dart';
import '../services/gigs_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/home/account_balance_section.dart';

class MyGigsScreen extends StatefulWidget {
  const MyGigsScreen({super.key});

  @override
  State<MyGigsScreen> createState() => _MyGigsScreenState();
}

class _MyGigsScreenState extends State<MyGigsScreen> {
  final UserStateService _userService = UserStateService();
  final GigsService _gigsService = GigsService();
  
  List<Map<String, dynamic>> _userGigs = [];
  List<Map<String, dynamic>> _filteredGigs = [];
  bool _isLoadingGigs = true;
  String _selectedFilter = 'all';
  
  @override
  void initState() {
    super.initState();
    _loadUserGigs();
  }
  
  Future<void> _loadUserGigs() async {
    setState(() => _isLoadingGigs = true);
    
    final currentUser = _userService.currentUser;
    
    if (currentUser?.id != null) {
      try {
        final userGigs = await _gigsService.fetchUserGigs(currentUser!.id);
        
        if (mounted) {
          setState(() {
            _userGigs = userGigs;
            _applyFilter();
            _isLoadingGigs = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingGigs = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoadingGigs = false;
      });
    }
  }
  
  void _applyFilter() {
    print('🔍 Applying filter: $_selectedFilter');
    print('📊 Total gigs: ${_userGigs.length}');
    
    List<Map<String, dynamic>> filtered;
    
    if (_selectedFilter == 'all') {
      filtered = List.from(_userGigs);
    } else {
      filtered = _userGigs.where((gig) {
        final gigStatus = gig['gig_status'] ?? '';
        final isActive = gig['active_gig'] ?? false;
        
        print('Gig: ${gig['title']}, Status: $gigStatus, Active: $isActive');
        
        switch (_selectedFilter) {
          case 'live':
            return gigStatus == 'approved' && isActive;
          case 'paused':
            return gigStatus == 'approved' && !isActive;
          case 'pending':
            return gigStatus == 'pending';
          case 'completed':
            return gigStatus == 'completed';
          case 'rejected':
            return gigStatus == 'rejected';
          default:
            return true;
        }
      }).toList();
    }
    
    print('✅ Filtered gigs: ${filtered.length}');
    _filteredGigs = filtered;
  }
  
  Future<void> _handleGigAction(String gigId, String action, bool value) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('${action == "completed" ? "Stopping" : value ? "Activating" : "Pausing"} gig...'),
          ],
        ),
        duration: const Duration(seconds: 30), // Longer duration for API call
      ),
    );
    
    try {
      final success = await _gigsService.updateGigStatus(gigId, action, value);
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                action == "completed" 
                    ? "Gig stopped successfully" 
                    : value 
                        ? "Gig activated successfully" 
                        : "Gig paused successfully"
              ),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh gigs
          _loadUserGigs();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${action == "completed" ? "stop" : value ? "activate" : "pause"} gig'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleEditGig(Map<String, dynamic> gig) async {
    // Navigate to edit gig page (to be implemented)
    // For now, show a dialog to increase quantity
    final gigId = gig['id']?.toString() ?? '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int additionalQuantity = 0;
        // Handle price as either String or number
        final priceValue = gig['price'];
        final price = priceValue is String 
            ? double.tryParse(priceValue) ?? 0.0 
            : (priceValue is num ? priceValue.toDouble() : 0.0);
        
        return AlertDialog(
          title: const Text('Increase Gig Quantity'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Quantity: ${gig['required_quantity']}'),
                  const SizedBox(height: 8),
                  Text('Price per action: ৳$price'),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Additional Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        additionalQuantity = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (additionalQuantity > 0) ...[
                    Text('Cost: ৳${(price * additionalQuantity).toStringAsFixed(2)}'),
                    Text('Fee (10%): ৳${(price * additionalQuantity * 0.1).toStringAsFixed(2)}'),
                    Text(
                      'Total: ৳${(price * additionalQuantity * 1.1).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (additionalQuantity > 0) {
                  Navigator.of(context).pop();
                  // Call update API
                  final success = await _updateGigQuantity(gigId, additionalQuantity, price);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success 
                            ? 'Gig quantity increased successfully' 
                            : 'Failed to increase quantity'
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                    if (success) {
                      _loadUserGigs();
                    }
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
  
  Future<bool> _updateGigQuantity(String gigId, int additionalQuantity, double price) async {
    try {
      final headers = await ApiService.getHeaders();
      final additionalCost = price * additionalQuantity * 1.1; // Include 10% fee
      final balance = price * additionalQuantity;
      
      final response = await http.put(
        Uri.parse(ApiService.getApiUrl('update-user-micro-gig/$gigId/')),
        headers: headers,
        body: json.encode({
          'required_quantity': additionalQuantity,
          'additional_cost': additionalCost,
          'balance': balance,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleResubmitGig(Map<String, dynamic> gig) async {
    final gigId = gig['id']?.toString() ?? '';
    final rejectionReason = gig['rejection_reason'] ?? 'No reason provided';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final titleController = TextEditingController(text: gig['title']);
        final instructionsController = TextEditingController(text: gig['instructions']);
        
        return AlertDialog(
          title: const Text('Edit & Resubmit Gig'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rejection Reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rejectionReason,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 8),
                Text(
                  'Edit the content above to address the rejection reason, then resubmit for approval.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('Resubmitting gig...'),
                      ],
                    ),
                    duration: Duration(seconds: 30),
                  ),
                );
                
                final success = await _resubmitGig(
                  gigId,
                  titleController.text,
                  instructionsController.text,
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Gig resubmitted successfully! Waiting for approval.'
                            : 'Failed to resubmit gig'
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                  if (success) {
                    // Reload the gigs to reflect the new status
                    await _loadUserGigs();
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Resubmit for Approval', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _resubmitGig(String gigId, String title, String instructions) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.put(
        Uri.parse(ApiService.getApiUrl('update-user-micro-gig/$gigId/')),
        headers: headers,
        body: json.encode({
          'title': title,
          'instructions': instructions,
          'gig_status': 'pending', // Change status back to pending
          'rejection_reason': '', // Clear rejection reason
        }),
      );
      
      if (response.statusCode == 200) {
        // Small delay to ensure backend processes the update
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleGigDetails(Map<String, dynamic> gig) async {
    try {
      final gigDetails = await _gigsService.getGigDetails(gig['id'].toString());
      
      if (mounted && gigDetails != null) {
        final isRejected = gigDetails['gig_status'] == 'rejected';
        final rejectionReason = gigDetails['rejection_reason'] ?? '';
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(gigDetails['title'] ?? 'Gig Details'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (gigDetails['category_details'] != null && gigDetails['category_details']['title'] != null)
                      _buildDetailRow('Category', gigDetails['category_details']['title']),
                    _buildDetailRow('Status', _getStatusText(gigDetails['gig_status'], gigDetails['active_gig'])),
                    _buildDetailRow('Price', '৳${gigDetails['price']}'),
                    _buildDetailRow('Progress', '${gigDetails['filled_quantity']}/${gigDetails['required_quantity']}'),
                    _buildDetailRow('Balance', '৳${gigDetails['balance']}'),
                    _buildDetailRow('Total Cost', '৳${gigDetails['total_cost']}'),
                    _buildDetailRow('Created', _formatDate(gigDetails['created_at'])),
                    if (isRejected && rejectionReason.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rejection Reason:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rejectionReason,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (gigDetails['instructions'] != null && gigDetails['instructions'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(gigDetails['instructions'].toString()),
                    ],
                  ],
                ),
              ),
              actions: [
                if (isRejected)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _handleResubmitGig(gigDetails);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Edit & Resubmit', style: TextStyle(color: Colors.white)),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load gig details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    print('🔨 Building MyGigsScreen - Filter: $_selectedFilter, Filtered: ${_filteredGigs.length}, Total: ${_userGigs.length}');
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.work_outline,
                size: 16,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'My Gigs',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            children: [
              // Account Balance Section
              const AccountBalanceSection(),
              
              // User Gigs Section
              _buildUserGigsSection(isMobile),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUserGigsSection(bool isMobile) {
    if (!AuthService.isAuthenticated) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.login, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Please login to view your gigs',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.work_outline,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'My Gigs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    underline: Container(),
                    icon: const Icon(Icons.filter_list, size: 16),
                    isDense: true,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'live', child: Text('Live')),
                      DropdownMenuItem(value: 'paused', child: Text('Paused')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        print('🔄 Dropdown changed to: $newValue');
                        setState(() {
                          _selectedFilter = newValue;
                          
                          // Apply filter inline to ensure state update
                          if (_selectedFilter == 'all') {
                            _filteredGigs = List.from(_userGigs);
                          } else {
                            _filteredGigs = _userGigs.where((gig) {
                              final gigStatus = gig['gig_status'] ?? '';
                              final isActive = gig['active_gig'] ?? false;
                              
                              switch (_selectedFilter) {
                                case 'live':
                                  return gigStatus == 'approved' && isActive;
                                case 'paused':
                                  return gigStatus == 'approved' && !isActive;
                                case 'pending':
                                  return gigStatus == 'pending';
                                case 'completed':
                                  return gigStatus == 'completed';
                                case 'rejected':
                                  return gigStatus == 'rejected';
                                default:
                                  return true;
                              }
                            }).toList();
                          }
                          
                          print('✅ Filter applied. Showing ${_filteredGigs.length} gigs');
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          if (_isLoadingGigs)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredGigs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _userGigs.isEmpty ? 'No gigs found' : 'No gigs match the selected filter',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (_userGigs.isEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/post-a-gig'),
                      child: const Text('Create Your First Gig'),
                    ),
                  ],
                ],
              ),
            )
          else
            ListView.separated(
              key: ValueKey('gigs_list_${_selectedFilter}_${_filteredGigs.length}'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredGigs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final gig = _filteredGigs[index];
                return _buildGigCard(gig, isMobile);
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildGigCard(Map<String, dynamic> gig, bool isMobile) {
    final categoryDetails = gig['category_details'];
    final gigStatus = gig['gig_status'] ?? '';
    final isActive = gig['active_gig'] ?? false;
    final isCompleted = gigStatus == 'completed';
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50.withOpacity(0.7),
      ),
      child: Column(
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGigHeader(gig, categoryDetails, gigStatus, isActive),
                const SizedBox(height: 16),
                _buildGigInfo(gig),
                const SizedBox(height: 16),
                _buildGigActions(gig, isActive, isCompleted, isMobile),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildGigHeader(gig, categoryDetails, gigStatus, isActive),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildGigInfo(gig),
                ),
                const SizedBox(width: 20),
                _buildGigActions(gig, isActive, isCompleted, isMobile),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildGigHeader(Map<String, dynamic> gig, Map<String, dynamic>? categoryDetails, String gigStatus, bool isActive) {
    return Row(
      children: [
        // Category Image
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CachedNetworkImage(
            imageUrl: categoryDetails?['image'] ?? '',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.category, color: Colors.grey.shade600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Gig Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Name
              if (categoryDetails?['title'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    categoryDetails!['title'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              // Status and Title
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(gigStatus, isActive),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(gigStatus, isActive),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(gigStatus, isActive),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('|', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      gig['title'] ?? 'Untitled Gig',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildGigInfo(Map<String, dynamic> gig) {
    return Row(
      children: [
        // Completion count
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${gig['filled_quantity'] ?? 0}/${gig['required_quantity'] ?? 0}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(width: 16),
        
        // Amount
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('৳', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(
              '${gig['balance'] ?? 0}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
            Text(
              '/৳${gig['total_cost'] ?? 0}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        
        // Date posted
        Text(
          _formatDate(gig['created_at']),
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
  
  Widget _buildGigActions(Map<String, dynamic> gig, bool isActive, bool isCompleted, bool isMobile) {
    final gigId = gig['id']?.toString() ?? '';
    final gigStatus = gig['gig_status'] ?? '';
    final isRejected = gigStatus == 'rejected';
    final isPending = gigStatus == 'pending';
    final isApproved = gigStatus == 'approved';
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Only show Pause/Activate for approved gigs
        if (isApproved && !isCompleted && isActive)
          _buildActionButton(
            'Pause',
            Colors.orange,
            () => _handleGigAction(gigId, 'pause', false),
          ),
        if (isApproved && !isCompleted && !isActive)
          _buildActionButton(
            'Activate',
            Colors.green,
            () => _handleGigAction(gigId, 'active', true),
          ),
        if (!isCompleted && !isRejected && !isPending)
          _buildActionButton(
            'Edit',
            Colors.blue,
            () => _handleEditGig(gig),
          ),
        if (isRejected)
          _buildActionButton(
            'Appeal',
            Colors.blue,
            () => _handleResubmitGig(gig),
          ),
        if (!isCompleted && !isRejected && !isPending)
          _buildActionButton(
            'Stop',
            Colors.red,
            () => _showStopConfirmation(gigId),
          ),
        _buildActionButton(
          'Details',
          Colors.grey.shade700,
          () => _handleGigDetails(gig),
        ),
      ],
    );
  }
  
  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
  
  void _showStopConfirmation(String gigId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stop this gig?'),
          content: const Text(
            'This action will permanently stop the current gig and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleGigAction(gigId, 'completed', false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Stop Gig', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  
  Color _getStatusColor(String status, bool isActive) {
    switch (status) {
      case 'approved':
        return isActive ? Colors.green : Colors.red;
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String status, bool isActive) {
    switch (status) {
      case 'approved':
        return isActive ? 'Live' : 'Paused';
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }
  
  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt.toString());
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return '';
    }
  }
}
