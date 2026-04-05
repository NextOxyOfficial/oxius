import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/wallet_service.dart';
import '../../widgets/wallet/web_checkout_frame.dart';

class PaymentVerificationScreen extends StatefulWidget {
  final String orderId;
  final String verificationOrderId;
  final String checkoutUrl;
  final double amount;
  final bool resumeOnly;
  final String? initialGatewayUrl;

  const PaymentVerificationScreen({
    super.key,
    required this.orderId,
    required this.verificationOrderId,
    required this.checkoutUrl,
    required this.amount,
    this.resumeOnly = false,
    this.initialGatewayUrl,
  });

  @override
  State<PaymentVerificationScreen> createState() => _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  static const _slate50 = Color(0xFFF8FAFC);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _slate300 = Color(0xFFCBD5E1);
  static const _slate500 = Color(0xFF64748B);
  static const _slate800 = Color(0xFF1E293B);
  static const _emerald = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);
  static const _amber = Color(0xFFF59E0B);
  static const _indigo = Color(0xFF6366F1);

  late final WebViewController _webViewController;
  Timer? _pollingTimer;
  bool _isPageLoading = true;
  bool _isCheckingStatus = false;
  bool _isCompleted = false;
  bool _didTriggerAutoClose = false;
  int _pollAttempts = 0;
  String _status = 'processing';
  String _message = 'Opening secure checkout...';
  String _currentUrl = '';
  late String _activeVerificationOrderId;
  Map<String, dynamic>? _paymentDetails;
  bool _openedExternalFallback = false;

  bool get _supportsEmbeddedCheckout {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  bool get _usesWebEmbeddedCheckout {
    return kIsWeb;
  }

  bool get _usesWindowsEmbeddedCheckout {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  void initState() {
    super.initState();
    _activeVerificationOrderId = widget.verificationOrderId;

    if (widget.resumeOnly) {
      _isPageLoading = false;
      _message = 'Confirming your payment...';

      final initialGatewayUrl = widget.initialGatewayUrl;
      if (initialGatewayUrl != null && initialGatewayUrl.isNotEmpty) {
        _handleGatewayUrl(initialGatewayUrl);
      }

      _startPolling();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPaymentStatus(forceMessage: 'Confirming your payment...');
      });
      return;
    }

    if (_supportsEmbeddedCheckout) {
      if (_usesWindowsEmbeddedCheckout || _usesWebEmbeddedCheckout) {
        _message = 'Loading secure payment page...';
      } else {
        _configureWebView();
      }
      _startPolling();
    } else {
      _status = 'unsupported';
      _isPageLoading = false;
      _message =
          'This platform cannot host the in-app payment view. Use Android or iPhone for the embedded checkout, or open the secure payment page here only for testing.';
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _configureWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isPageLoading = true;
              _currentUrl = url;
              if (!_isCompleted) {
                _message = 'Loading secure payment page...';
              }
            });
            _handleGatewayUrl(url);
          },
          onPageFinished: (url) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isPageLoading = false;
              _currentUrl = url;
              if (!_isCompleted && _status == 'processing') {
                _message =
                    'Choose a payment method and complete the checkout inside the app.';
              }
            });
          },
          onNavigationRequest: (request) {
            _handleGatewayUrl(request.url);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (!mounted || _isCompleted) {
              return;
            }
            setState(() {
              _isPageLoading = false;
              _message =
                  'Checkout page had a loading issue. We are still checking your payment status.';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollAttempts++;

      if (_pollAttempts > 80) {
        timer.cancel();
        if (!mounted || _isCompleted) {
          return;
        }
        setState(() {
          _status = 'timeout';
          _message =
              'We could not confirm the payment yet. You can retry verification or close this screen.';
        });
        return;
      }

      await _checkPaymentStatus();
    });
  }

  void _handleWebViewLoadStart(String url) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isPageLoading = true;
      _currentUrl = url;
      if (!_isCompleted) {
        _message = 'Loading secure payment page...';
      }
    });
    _handleGatewayUrl(url);
  }

  void _handleWebViewLoadStop(String url) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isPageLoading = false;
      _currentUrl = url;
      if (!_isCompleted && _status == 'processing') {
        _message =
            'Choose a payment method and complete the checkout inside the app.';
      }
    });
  }

  void _handleWebViewLoadError() {
    if (!mounted || _isCompleted) {
      return;
    }

    setState(() {
      _isPageLoading = false;
      _message =
          'Checkout page had a loading issue. We are still checking your payment status.';
    });
  }

  void _handleGatewayUrl(String url) {
    final resolvedOrderId = _extractVerificationOrderIdFromUrl(url);
    if (resolvedOrderId != null && resolvedOrderId.isNotEmpty) {
      _activeVerificationOrderId = resolvedOrderId;
    }

    final normalizedUrl = url.toLowerCase();

    if (_isCompleted) {
      return;
    }

    if (normalizedUrl.contains('deposit-withdraw') ||
        normalizedUrl.contains('payment-cancel')) {
      _pollingTimer?.cancel();
      WalletService.clearPendingPaymentSession();
      if (mounted) {
        setState(() {
          _status = 'cancelled';
          _message = 'Payment was cancelled before completion.';
        });
      }
      return;
    }

    final looksLikeReturnUrl = normalizedUrl.contains('verify-payment') ||
        normalizedUrl.contains('verify-pay') ||
      normalizedUrl.contains('payment-callback') ||
        ((normalizedUrl.contains('order_id=') ||
                normalizedUrl.contains('sp_order_id=')) &&
            normalizedUrl.contains(widget.orderId.toLowerCase()));

    if (looksLikeReturnUrl) {
      _checkPaymentStatus(forceMessage: 'Confirming your payment...');
    }
  }

  Future<void> _checkPaymentStatus({String? forceMessage}) async {
    if (_isCheckingStatus || _isCompleted) {
      return;
    }

    _isCheckingStatus = true;

    try {
      if (mounted && forceMessage != null) {
        setState(() {
          _message = forceMessage;
        });
      }

      final result = await WalletService.verifyAndFinalizePayment(
        _activeVerificationOrderId,
      );

      if (!mounted) {
        return;
      }

      final status = result['status']?.toString() ?? 'pending';
      final paymentDetails = result['paymentDetails'];

      if (status == 'success' && result['success'] == true) {
        _pollingTimer?.cancel();
        _isCompleted = true;

        setState(() {
          _status = 'success';
          _message = result['message']?.toString() ??
              'Payment successful! Your balance has been updated.';
          if (paymentDetails is Map<String, dynamic>) {
            _paymentDetails = paymentDetails;
          }
        });
        WalletService.clearPendingPaymentSession();

        if (!_didTriggerAutoClose) {
          _didTriggerAutoClose = true;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
        return;
      }

      if (status == 'failed') {
        _pollingTimer?.cancel();
        _isCompleted = true;

        setState(() {
          _status = 'failed';
          _message =
              result['message']?.toString() ?? 'Payment could not be completed.';
          if (paymentDetails is Map<String, dynamic>) {
            _paymentDetails = paymentDetails;
          }
        });
        WalletService.clearPendingPaymentSession();
        return;
      }

      if (mounted) {
        setState(() {
          _status = 'processing';
          _message = result['message']?.toString() ??
              'Waiting for payment confirmation from the gateway...';
        });
      }
    } catch (e) {
      if (!mounted || _isCompleted) {
        return;
      }

      setState(() {
        _status = 'processing';
        _message =
            'Still waiting for confirmation from the payment gateway. Please complete the payment to continue.';
      });
    } finally {
      _isCheckingStatus = false;
    }
  }

  String? _extractVerificationOrderIdFromUrl(String url) {
    return WalletService.extractVerificationOrderIdFromUrl(url);
  }

  Future<bool> _handleBackPress() async {
    if (_isCompleted) {
      return true;
    }

    final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              'Leave payment?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'If you leave now, your payment may still continue in the gateway, but the app will stop monitoring it on this screen.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _slate500,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Stay',
                  style: GoogleFonts.inter(
                    color: _slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _slate800,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Leave',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;

    return shouldLeave;
  }

  Future<void> _openExternalCheckout() async {
    final uri = Uri.tryParse(widget.checkoutUrl);

    if (uri == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Secure checkout URL is invalid.'),
          backgroundColor: _red,
        ),
      );
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) {
      return;
    }

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the payment page on this device.'),
          backgroundColor: _red,
        ),
      );
      return;
    }

    _openedExternalFallback = true;
    setState(() {
      _status = 'processing';
      _message =
          'Complete the payment in the browser. This screen will keep checking the deposit status.';
    });
    _startPolling();
  }

  Color _statusColor() {
    switch (_status) {
      case 'success':
        return _emerald;
      case 'failed':
      case 'cancelled':
        return _red;
      case 'timeout':
        return _amber;
      default:
        return _indigo;
    }
  }

  IconData _statusIcon() {
    switch (_status) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'failed':
      case 'cancelled':
        return Icons.error_rounded;
      case 'timeout':
        return Icons.schedule_rounded;
      default:
        return Icons.lock_clock_rounded;
    }
  }

  String _statusTitle() {
    switch (_status) {
      case 'success':
        return 'Deposit complete';
      case 'failed':
        return 'Payment failed';
      case 'cancelled':
        return 'Payment cancelled';
      case 'timeout':
        return 'Still verifying';
      default:
        return 'Secure checkout';
    }
  }

  Widget _buildProgressStep({
    required IconData icon,
    required String label,
    required bool active,
    required bool done,
  }) {
    final color = done ? _emerald : (active ? _indigo : _slate300);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: done || active ? _slate800 : _slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final color = _statusColor();
    final transactionId = _paymentDetails?['shurjopay_order_id']?.toString() ??
        widget.orderId;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcon(), color: color, size: 44),
              ),
              const SizedBox(height: 18),
              Text(
                _statusTitle(),
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _slate800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: _slate500,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _slate50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _slate100),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Amount',
                        '৳${widget.amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Transaction ID',
                      transactionId.length > 18
                          ? '${transactionId.substring(0, 18)}...'
                          : transactionId,
                    ),
                    if (_paymentDetails?['payment_method'] != null) ...[
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        'Method',
                        _paymentDetails!['payment_method'].toString(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_status == 'timeout')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _status = 'processing';
                        _message =
                            'Retrying payment verification. Please wait...';
                        _pollAttempts = 0;
                      });
                      _startPolling();
                      _checkPaymentStatus(
                        forceMessage: 'Retrying payment verification...',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _indigo,
                      side: BorderSide(color: _indigo.withValues(alpha: 0.24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Check again',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .pop(_status == 'success'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _status == 'success' ? 'Back to wallet' : 'Close',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnsupportedPlatformView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.devices_outlined,
                  size: 42,
                  color: _amber,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Desktop Preview Limitation',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _slate800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: _slate500,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _slate50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _slate100),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Amount', '৳${widget.amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Order',
                      widget.orderId.length > 18
                          ? '${widget.orderId.substring(0, 18)}...'
                          : widget.orderId,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openExternalCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _slate800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _openedExternalFallback
                        ? 'Open checkout again'
                        : 'Open secure checkout in browser',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _checkPaymentStatus(
                      forceMessage: 'Checking payment status from the gateway...',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _indigo,
                    side: BorderSide(color: _indigo.withValues(alpha: 0.24)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'I already paid, check now',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'On Android and iPhone, this payment opens inside the app. Windows desktop cannot render this gateway with the current Flutter webview plugin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.5,
                  color: _slate500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebCheckoutPane() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _slate100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_isPageLoading)
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: _indigo,
                  backgroundColor: Color(0xFFE2E8F0),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: WebCheckoutFrame(
                    checkoutUrl: widget.checkoutUrl,
                    onPageLoaded: (loadedUrl) {
                      _handleWebViewLoadStop(loadedUrl);
                      _handleGatewayUrl(loadedUrl);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmbeddedCheckoutBody() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _statusColor().withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _statusIcon(),
                          color: _statusColor(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusTitle(),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _slate800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _message,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                height: 1.45,
                                color: _slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _buildProgressStep(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Checkout',
                        active: true,
                        done: !_isPageLoading,
                      ),
                      _buildProgressStep(
                        icon: Icons.payments_outlined,
                        label: 'Payment',
                        active: !_isPageLoading,
                        done: _currentUrl.isNotEmpty,
                      ),
                      _buildProgressStep(
                        icon: Icons.verified_outlined,
                        label: 'Verify',
                        active: _isCheckingStatus,
                        done: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _slate50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _slate100),
                    ),
                    child: Row(
                      children: [
                        _buildSummaryPill(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Amount',
                          value: '৳${widget.amount.toStringAsFixed(2)}',
                        ),
                        const SizedBox(width: 12),
                        _buildSummaryPill(
                          icon: Icons.receipt_long_outlined,
                          label: 'Order',
                          value: widget.orderId.length > 12
                              ? '${widget.orderId.substring(0, 12)}...'
                              : widget.orderId,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_usesWebEmbeddedCheckout)
            _buildWebCheckoutPane()
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 16),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _slate100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _usesWindowsEmbeddedCheckout
                            ? InAppWebView(
                                initialSettings: InAppWebViewSettings(
                                  javaScriptEnabled: true,
                                  transparentBackground: false,
                                  useShouldOverrideUrlLoading: true,
                                ),
                                initialUrlRequest: URLRequest(
                                  url: WebUri(widget.checkoutUrl),
                                ),
                                onLoadStart: (controller, url) {
                                  _handleWebViewLoadStart(url?.toString() ?? '');
                                },
                                onLoadStop: (controller, url) {
                                  _handleWebViewLoadStop(url?.toString() ?? '');
                                },
                                shouldOverrideUrlLoading:
                                    (controller, navigationAction) async {
                                  final currentUrl = navigationAction
                                          .request.url
                                          ?.toString() ??
                                      '';
                                  _handleGatewayUrl(currentUrl);
                                  return NavigationActionPolicy.ALLOW;
                                },
                                onReceivedError: (controller, request, error) {
                                  _handleWebViewLoadError();
                                },
                                onReceivedHttpError:
                                    (controller, request, errorResponse) {
                                  _handleWebViewLoadError();
                                },
                              )
                            : WebViewWidget(
                                controller: _webViewController,
                              ),
                      ),
                      if (_isPageLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: _indigo,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Loading secure checkout...',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationOnlyBody() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _indigo,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Verifying payment',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _slate800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: _slate500,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _slate50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _slate100),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Amount', '৳${widget.amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Order',
                      _activeVerificationOrderId.length > 18
                          ? '${_activeVerificationOrderId.substring(0, 18)}...'
                          : _activeVerificationOrderId,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _slate500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _slate800,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFinished =
        _status == 'success' || _status == 'failed' || _status == 'cancelled';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        final navigator = Navigator.of(context);
        final shouldLeave = await _handleBackPress();
        if (shouldLeave && mounted) {
          navigator.pop(_status == 'success');
        }
      },
      child: Scaffold(
        backgroundColor: _slate50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: _slate800,
          elevation: 0,
          title: Text(
            'Complete Deposit',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _slate800,
            ),
          ),
        ),
        body: !_supportsEmbeddedCheckout
          ? _buildUnsupportedPlatformView()
          : AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: isFinished || _status == 'timeout'
              ? _buildResultView()
              : widget.resumeOnly
                  ? _buildVerificationOnlyBody()
                  : _buildEmbeddedCheckoutBody(),
        ),
      ),
    );
  }

  Widget _buildSummaryPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _slate100),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _indigo),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _slate500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _slate800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
