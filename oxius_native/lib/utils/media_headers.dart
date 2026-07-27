/// Headers every remote media request must carry.
///
/// The CDN in front of `media.adsyclub.com` turns away requests with no (or a
/// default Dart) User-Agent, so a bare `Image.network` silently fails while
/// the feed — which sends this — loads fine. That mismatch is why the profile
/// media grid showed grey placeholders for photos and videos the feed had no
/// trouble with. Import this instead of writing the map again.
const Map<String, String> kMediaHeaders = {'User-Agent': 'OxiUsFlutter/1.0'};
