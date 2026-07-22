import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// iOS renders SF Pro (and the Bangla fallback fonts) visually smaller than
/// Roboto at the same logical pixel size, so AdsyConnect surfaces looked
/// noticeably tiny on iPhones while being fine on Android. These helpers
/// compensate on iOS ONLY — Android output is untouched.

/// Extra text scale applied on iOS inside [AdsyIosTextBoost] subtrees.
const double kAdsyIosTextBoost = 1.12;

/// Multiplier for avatar/image box sizes on iOS (containers don't follow the
/// text scaler). 1.0 everywhere else.
double adsyIosBoxScale() =>
    defaultTargetPlatform == TargetPlatform.iOS ? 1.15 : 1.0;

/// Wrap a subtree to boost ALL its text by [kAdsyIosTextBoost] on iOS while
/// still honouring the user's system accessibility scale.
class AdsyIosTextBoost extends StatelessWidget {
  final Widget child;

  const AdsyIosTextBoost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return child;
    final mq = MediaQuery.of(context);
    final current = mq.textScaler.scale(1.0);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: TextScaler.linear(current * kAdsyIosTextBoost),
      ),
      child: child,
    );
  }
}
