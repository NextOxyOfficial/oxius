import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oxius_native/models/rideshare_models.dart';
import 'package:oxius_native/screens/rideshare/rideshare_map_widget.dart';

/// The map's status panel is a lid over exactly the part of the map the rider
/// is trying to aim at, so it has to fold away on tap — and fold in BOTH axes,
/// which is the part that is easy to get subtly wrong (a vertical-only fold
/// leaves a full-width bar sitting there looking broken).
void main() {
  setUpAll(() {
    // Otherwise every Text tries to pull a font over the network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// The basemap tiles 400 under the test HTTP client and every failure is
  /// reported as an unexpected exception, which fails the test for reasons
  /// that have nothing to do with the panel. Drop just those.
  ///
  /// Has to run inside the test body — the binding installs its own handler
  /// when the test starts, so anything set in setUp is overwritten.
  void silenceTileErrors() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.library == 'image resource service') return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);
  }

  Widget harness() => MaterialApp(
        home: Scaffold(
          body: RideshareMapWidget(
            pickupPoint: RidePoint(
              name: 'Pickup',
              latitude: 23.8103,
              longitude: 90.4125,
            ),
            dropPoint: RidePoint(
              name: 'Drop',
              latitude: 23.8203,
              longitude: 90.4225,
            ),
            activeSelection: 'drop',
            onMapTap: (_, __) {},
          ),
        ),
      );

  /// The glass box around the panel — what actually covers the map.
  Size panelSize(WidgetTester tester) {
    final finder = find.ancestor(
      of: find.byIcon(Icons.touch_app_rounded),
      matching: find.byType(BackdropFilter),
    );
    expect(finder, findsOneWidget);
    return tester.getSize(finder);
  }

  testWidgets('status panel folds away on tap and comes back', (tester) async {
    silenceTileErrors();
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('রুট প্ল্যানার'), findsOneWidget);
    final open = panelSize(tester);

    await tester.tap(find.byIcon(Icons.touch_app_rounded));
    await tester.pumpAndSettle();

    final closed = panelSize(tester);

    // The wording and the chip are what make it wide; both must be gone.
    expect(closed.width, lessThan(open.width * 0.55),
        reason: 'closed panel still $closed vs open $open — width did not fold');
    expect(closed.height, lessThan(open.height * 0.75),
        reason: 'closed panel still $closed vs open $open — height did not fold');

    // A closed panel that cannot be reopened is a lost feature, not a fix.
    await tester.tap(find.byIcon(Icons.touch_app_rounded));
    await tester.pumpAndSettle();

    final reopened = panelSize(tester);
    expect(reopened.width, closeTo(open.width, 0.5));
    expect(reopened.height, closeTo(open.height, 0.5));
  });

  testWidgets('closed panel keeps the badge tappable, not a hairline',
      (tester) async {
    silenceTileErrors();
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.touch_app_rounded));
    await tester.pumpAndSettle();

    final closed = panelSize(tester);
    expect(closed.width, greaterThan(60));
    expect(closed.height, greaterThan(40));
  });

  testWidgets('layers button switches the basemap to satellite + labels',
      (tester) async {
    silenceTileErrors();
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 50));

    List<TileLayer> tileLayers() =>
        tester.widgetList<TileLayer>(find.byType(TileLayer)).toList();

    // Street: one Carto layer, no overlay.
    expect(tileLayers(), hasLength(1));
    expect(tileLayers().single.urlTemplate, contains('cartocdn.com'));

    await tester.tap(find.byIcon(Icons.layers_rounded));
    await tester.pump();

    // Satellite: Esri imagery underneath, the reference labels on top —
    // imagery on its own is unusable for choosing a pickup.
    final satellite = tileLayers();
    expect(satellite, hasLength(2));
    expect(satellite.first.urlTemplate, contains('World_Imagery'));
    expect(satellite.last.urlTemplate, contains('World_Boundaries_and_Places'));
    // Esri has no '{r}' variant, so asking for retina would silently switch
    // flutter_map to *simulated* retina — fetching a zoom level deeper than
    // the rider asked for on every tile.
    expect(satellite.first.resolvedRetinaMode, RetinaMode.disabled);

    // And back.
    await tester.tap(find.byIcon(Icons.satellite_alt_rounded));
    await tester.pump();
    expect(tileLayers(), hasLength(1));
    expect(tileLayers().single.urlTemplate, contains('cartocdn.com'));
  });

  testWidgets('topInset pushes the panel clear of the shell controls',
      (tester) async {
    silenceTileErrors();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RideshareMapWidget(
          activeSelection: 'drop',
          onMapTap: (_, __) {},
          topInset: 96,
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 50));

    final top = tester
        .getTopLeft(find.ancestor(
          of: find.byIcon(Icons.touch_app_rounded),
          matching: find.byType(BackdropFilter),
        ))
        .dy;
    expect(top, closeTo(96, 0.5));
  });
}
