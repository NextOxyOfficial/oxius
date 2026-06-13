import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/user_state_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final UserStateService _userState = UserStateService();
  final ImagePicker _picker = ImagePicker();
  final Map<String, bool> _errors = {
    'front': false,
    'back': false,
    'selfie': false,
  };

  bool _isLoading = false;
  bool _isPending = false;
  bool _isVerified = false;

  String? _frontImage;
  String? _backImage;
  String? _selfieImage;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(ApiService.getApiUrl('get-user-nid/')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted && data['data'] != null) {
          setState(() {
            _isPending = data['data']['pending'] ?? false;
            _isVerified = data['data']['approved'] ?? false;
            _frontImage = data['data']['front'] != null
                ? '${ApiService.baseUrl}${data['data']['front']}'
                : _frontImage;
            _backImage = data['data']['back'] != null
                ? '${ApiService.baseUrl}${data['data']['back']}'
                : _backImage;
            _selfieImage = data['data']['selfie'] != null
                ? '${ApiService.baseUrl}${data['data']['selfie']}'
                : _selfieImage;
          });
        }
      }
    } catch (error) {
      debugPrint('Error loading verification status: $error');
    }
  }

  int _calculateProgress() {
    int completed = 0;
    if (_frontImage != null) completed++;
    if (_backImage != null) completed++;
    if (_selfieImage != null) completed++;
    return ((completed / 3) * 100).floor();
  }

  /// Documents are considered locked once they have been submitted for
  /// review (pending) or approved. In both states the user must not be able
  /// to upload / replace / delete — verification is out of their hands until
  /// support resets it. This is the single source of truth used by the
  /// upload cards, the submit button and the picker/delete handlers.
  bool get _isLocked => _isPending || _isVerified;

  Future<void> _pickImage(String field) async {
    if (_isLocked) {
      // Defensive: UI already hides the entry points, but if anything still
      // triggers a pick (e.g. an in-flight tap during state transition) we
      // refuse silently to keep submitted documents immutable.
      return;
    }
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 70,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      if (bytes.length > 12 * 1024 * 1024) {
        if (!mounted) {
          return;
        }
        AdsyToast.error(context, 'File size too large. Maximum size is 12MB.');
        return;
      }

      final base64String = base64Encode(bytes);
      setState(() {
        switch (field) {
          case 'front':
            _frontImage = 'data:image/jpeg;base64,$base64String';
            _errors['front'] = false;
            break;
          case 'back':
            _backImage = 'data:image/jpeg;base64,$base64String';
            _errors['back'] = false;
            break;
          case 'selfie':
            _selfieImage = 'data:image/jpeg;base64,$base64String';
            _errors['selfie'] = false;
            break;
        }
      });
    } catch (error) {
      debugPrint('Error picking image: $error');
      if (!mounted) {
        return;
      }
      AdsyToast.error(context, 'Error selecting image. Please try again.');
    }
  }

  void _deleteImage(String field) {
    if (_isLocked) {
      // Submitted / approved documents are immutable. UI hides the Remove
      // button, this is the defensive backstop.
      return;
    }
    setState(() {
      switch (field) {
        case 'front':
          _frontImage = null;
          break;
        case 'back':
          _backImage = null;
          break;
        case 'selfie':
          _selfieImage = null;
          break;
      }
    });
  }

  Future<void> _submitDocuments() async {
    if (_isLocked) {
      return;
    }
    setState(() {
      _errors['front'] = _frontImage == null;
      _errors['back'] = _backImage == null;
      _errors['selfie'] = _selfieImage == null;
    });

    if (_errors.values.any((hasError) => hasError)) {
      AdsyToast.warning(context, 'Please fill in all required fields.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse(ApiService.getApiUrl('add-user-nid/')),
        headers: headers,
        body: json.encode({
          'front': _frontImage,
          'back': _backImage,
          'selfie': _selfieImage,
        }),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        AdsyToast.success(
            context, data['message'] ?? 'Documents submitted successfully!');
        await _loadVerificationStatus();
      } else {
        AdsyToast.error(context, 'Failed to submit documents. Please try again.');
      }
    } catch (error) {
      debugPrint('Error submitting documents: $error');
      if (!mounted) {
        return;
      }
      AdsyToast.error(context, 'An error occurred. Please try again later.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x1910B981),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 18,
                color: Color(0xFF0F766E),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Verification',
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 210,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F766E),
                    Color(0xFF10B981),
                    Color(0xFF6EE7B7),
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            child: Column(
              children: [
                _buildHeroCard(theme),
                const SizedBox(height: 18),
                _buildInstructionsCard(),
                const SizedBox(height: 18),
                if (_isPending)
                  _buildPendingStatus()
                else if (_isVerified)
                  _buildVerifiedStatus()
                else
                  _buildUploadSection(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    final Color chipColor = _isVerified
        ? const Color(0xFFDCFCE7)
        : _isPending
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFFEE2E2);
    final Color chipTextColor = _isVerified
        ? const Color(0xFF166534)
        : _isPending
            ? const Color(0xFF92400E)
            : const Color(0xFFB91C1C);
    final int progress = _isVerified ? 100 : _calculateProgress();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE2FDF3), Color(0xFFD1FAE5)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _isVerified
                      ? Icons.verified_rounded
                      : _isPending
                          ? Icons.hourglass_top_rounded
                          : Icons.shield_outlined,
                  color: const Color(0xFF059669),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userState.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isVerified
                          ? 'Your identity is fully approved and ready to use.'
                          : _isPending
                              ? 'Your documents are under review by our team.'
                              : 'Complete document upload to unlock verification.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _isVerified
                      ? 'Verified'
                      : _isPending
                          ? 'Reviewing'
                          : 'Unverified',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: chipTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8FAFC), Color(0xFFECFDF5)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isVerified
                            ? 'Verification completed'
                            : 'Verification progress',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isVerified
                            ? 'Your account now meets the document check requirements.'
                            : '$progress% of your required documents are ready.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1F10B981),
                        blurRadius: 14,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Static determinate ring (NOT the animated AdsyLoading
                      // spinner) — this just shows how much of the form is
                      // filled, so it must not look like a "verification in
                      // progress" loader before anything is submitted.
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: progress / 100,
                          strokeWidth: 7,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981)),
                        ),
                      ),
                      Text(
                        '$progress%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x1910B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Verification Instructions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Make sure every image is bright, readable, and fully visible before you submit.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _buildInstructionItem(
              'Capture all four corners of your document clearly'),
          _buildInstructionItem('Upload NID front, back, and a clear selfie'),
          _buildInstructionItem('We accept NID, Passport, and Driving License'),
          _buildInstructionItem(
              'Reviews usually complete within 24 to 48 hours'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, const Color(0xFFFFFBEB)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1FF59E0B),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.amber,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Verification in Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ID verification is currently under review by our team.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.amber.shade800,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.amber.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: null,
                backgroundColor: Colors.transparent,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.amber.shade500),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'We\'ll notify you as soon as approval is complete.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.amber.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, const Color(0xFFF0FDF4)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A10B981),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Account Verified',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your identity has been successfully verified!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.green.shade800,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'ID Verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x29FFFFFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_calculateProgress()}% done',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload clean, readable images for every required document.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildUploadField('ID Front', 'front', _frontImage,
                        _errors['front'] ?? false),
                    const SizedBox(height: 18),
                    _buildUploadField('ID Back', 'back', _backImage,
                        _errors['back'] ?? false),
                    const SizedBox(height: 18),
                    _buildUploadField('Selfie with ID', 'selfie', _selfieImage,
                        _errors['selfie'] ?? false),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Verification Progress',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Text(
                    '${_calculateProgress()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _calculateProgress() / 100,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                      child: _buildProgressIndicator(
                          'ID Front', _frontImage != null)),
                  Expanded(
                      child: _buildProgressIndicator(
                          'ID Back', _backImage != null)),
                  Expanded(
                      child: _buildProgressIndicator(
                          'Selfie', _selfieImage != null)),
                ],
              ),
              const SizedBox(height: 18),
              // Hide the submit button entirely once the user has already
              // submitted (pending review) or been approved. Keeping it
              // visible — even disabled — invites confusion and tap retries.
              if (!_isLocked)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitDocuments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: AdsyLoadingIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Submit Documents',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadField(
      String label, String field, String? image, bool hasError) {
    final bool locked = _isLocked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: image != null
                    ? const Color(0xFF10B981)
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (image != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: image.startsWith('http')
                      ? Image.network(
                          image,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.memory(
                          base64Decode(image.split(',').last),
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                // Once documents are submitted (pending review) or already
                // approved, the Replace / Remove actions must not appear —
                // submitted documents are immutable until support resets the
                // verification state. Show a read-only status chip instead.
                if (locked) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _isVerified
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isVerified
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFFED7AA),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isVerified
                              ? Icons.verified_rounded
                              : Icons.hourglass_top_rounded,
                          size: 16,
                          color: _isVerified
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isVerified
                              ? 'Approved'
                              : 'Submitted — awaiting review',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isVerified
                                ? const Color(0xFF065F46)
                                : const Color(0xFF9A3412),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(field),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(color: Color(0xFF99F6E4)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Replace'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _deleteImage(field),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            backgroundColor: const Color(0xFFFEF2F2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          label: const Text('Remove'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          )
        else if (!locked)
          GestureDetector(
            onTap: () => _pickImage(field),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFCFFFE), Color(0xFFF0FDFA)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color:
                      hasError ? Colors.red.shade300 : const Color(0xFF99F6E4),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0x1910B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Color(0xFF10B981),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to choose a clear image from your gallery',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$label is required',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProgressIndicator(String label, bool completed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: completed ? const Color(0xFF10B981) : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    completed ? const Color(0xFF047857) : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
