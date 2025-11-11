import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/eshop_manager_service.dart';
import '../../services/auth_service.dart';

class CreateStoreScreen extends StatefulWidget {
  final VoidCallback onStoreCreated;

  const CreateStoreScreen({
    super.key,
    required this.onStoreCreated,
  });

  @override
  State<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _storeUsernameController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _isCheckingUsername = false;
  bool _usernameChecked = false;
  bool _usernameAvailable = false;
  List<String> _usernameSuggestions = [];
  String? _usernameError;

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeUsernameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _storeUsernameController.text.trim().toLowerCase();
    
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _usernameChecked = false;
        _usernameAvailable = false;
        _usernameSuggestions = [];
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      final result = await EshopManagerService.checkStoreUsername(username);
      
      if (mounted) {
        setState(() {
          _usernameChecked = true;
          _usernameAvailable = result['available'] ?? false;
          _usernameSuggestions = (result['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
          _usernameError = _usernameAvailable ? null : 'This username is already taken';
        });
      }
    } catch (e) {
      print('Error checking username: $e');
      if (mounted) {
        setState(() {
          _usernameChecked = false;
          _usernameAvailable = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingUsername = false);
      }
    }
  }

  void _selectSuggestion(String suggestion) {
    setState(() {
      _storeUsernameController.text = suggestion;
      _usernameAvailable = true;
      _usernameSuggestions = [];
      _usernameError = null;
      _usernameChecked = true;
    });
  }

  Future<void> _handleCreateStore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_usernameChecked && !_usernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose an available username'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final storeName = _storeNameController.text.trim();
      final storeUsername = _storeUsernameController.text.trim().toLowerCase();

      await EshopManagerService.createStore(
        storeName: storeName,
        storeUsername: storeUsername,
      );

      // Refresh user data to get updated store info
      await AuthService.refreshUserData();

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Store Created Successfully!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your store "$storeName" has been created. You can now start adding products.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  widget.onStoreCreated(); // Trigger refresh
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Go to Store Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create store: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        size: 48,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create Your Store',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Set up your online store and start selling your products',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Form
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store Name
                      const Text(
                        'Store Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _storeNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your business name',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: const Icon(
                            Icons.store_rounded,
                            size: 20,
                            color: Color(0xFF6B7280),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF10B981)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(fontSize: 13),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Store name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Store Username
                      const Text(
                        'Store Username',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _storeUsernameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your store username',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: const Icon(
                            Icons.alternate_email,
                            size: 20,
                            color: Color(0xFF6B7280),
                          ),
                          suffixIcon: _isCheckingUsername
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF10B981)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(fontSize: 13),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_-]')),
                          LowerCaseTextFormatter(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _usernameChecked = false;
                            _usernameAvailable = false;
                            _usernameSuggestions = [];
                          });
                        },
                        onEditingComplete: _checkUsernameAvailability,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Store username is required';
                          }
                          if (value.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          if (_usernameError != null) {
                            return _usernameError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Username availability status
                      if (_usernameChecked && _storeUsernameController.text.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _usernameAvailable
                                ? const Color(0xFF10B981).withOpacity(0.1)
                                : const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _usernameAvailable
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 16,
                                color: _usernameAvailable
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _usernameAvailable
                                      ? 'Username is available!'
                                      : 'This username is already taken',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _usernameAvailable
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Username suggestions
                      if (_usernameSuggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Try one of these instead:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _usernameSuggestions.map((suggestion) {
                            return InkWell(
                              onTap: () => _selectSuggestion(suggestion),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  suggestion,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Store URL Preview
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your store URL will be:',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'https://adsyclub.com/eshop/',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  _storeUsernameController.text.isEmpty
                                      ? 'your-store'
                                      : _storeUsernameController.text,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleCreateStore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Create Store',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      
                      // Safe area bottom padding for devices with gesture navigation
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
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
}

// Custom text formatter to convert to lowercase
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}
