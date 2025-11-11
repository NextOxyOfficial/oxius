import 'package:flutter/material.dart';

/// A custom Scaffold that automatically handles bottom navigation bar overlap
/// on devices with gesture navigation. Use this instead of the standard Scaffold
/// for all new screens to ensure consistent safe area handling.
class SafeScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  
  /// If true, wraps bottomNavigationBar with SafeArea (default: true)
  final bool safeBottomBar;
  
  /// If true, adds bottom padding to body for scrollable content (default: false)
  /// Use this for screens with ListView/SingleChildScrollView without bottomNavigationBar
  final bool addBottomPadding;
  
  /// Additional bottom padding to add (default: 0)
  final double extraBottomPadding;

  const SafeScaffold({
    Key? key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.safeBottomBar = true,
    this.addBottomPadding = false,
    this.extraBottomPadding = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: addBottomPadding && body != null
          ? _BodyWithPadding(
              child: body!,
              extraPadding: extraBottomPadding,
            )
          : body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar != null && safeBottomBar
          ? SafeArea(child: bottomNavigationBar!)
          : bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}

class _BodyWithPadding extends StatelessWidget {
  final Widget child;
  final double extraPadding;

  const _BodyWithPadding({
    required this.child,
    this.extraPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        SizedBox(height: MediaQuery.of(context).padding.bottom + extraPadding),
      ],
    );
  }
}
