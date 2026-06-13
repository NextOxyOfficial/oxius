import 'package:flutter/material.dart';

/// Business Network feed native ad slot.
///
/// ── AppLovin MAX temporarily DISABLED (account approval pending) ──
/// This is a no-op stub that renders nothing, so the app builds and ships
/// without the AppLovin SDK. When the AppLovin account is approved:
///   1. Re-add `applovin_max` to pubspec.yaml.
///   2. Restore the real MAX `MaxNativeAdView` implementation here
///      (see git history for the previous version).
///   3. Restore the SDK init in `AdsService.init()`.
/// Until then `AdsService.placementActive(...)` returns false, so this card is
/// never even inserted into the feed — this stub is just a compile-time guard.
class FeedNativeAdCard extends StatelessWidget {
  final String placementKey;
  const FeedNativeAdCard({super.key, this.placementKey = 'bn_feed_native'});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
