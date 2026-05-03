import '../config/payment_config.dart';
import 'payment_service.dart';
import 'external_wallet_payment_service.dart';
import 'iap_payment_service.dart';

/// Returns the correct [PaymentService] implementation for the current
/// platform and configuration.
///
/// Switch to IAP by setting PaymentConfig.enableIAP = true.
/// No changes are needed at the call sites.
class PaymentServiceFactory {
  PaymentServiceFactory._();

  static const PaymentService _wallet = ExternalWalletPaymentService();
  static const PaymentService _iap = IAPPaymentService();

  /// Active payment service for digital purchases.
  static PaymentService get instance {
    if (PaymentConfig.enableIAP && PaymentConfig.isIOS) {
      return _iap;
    }
    return _wallet;
  }
}
