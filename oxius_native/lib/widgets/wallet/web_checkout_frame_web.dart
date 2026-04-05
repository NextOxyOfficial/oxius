// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class WebCheckoutFrame extends StatefulWidget {
  final String checkoutUrl;
  final ValueChanged<String>? onPageLoaded;

  const WebCheckoutFrame({
    super.key,
    required this.checkoutUrl,
    this.onPageLoaded,
  });

  @override
  State<WebCheckoutFrame> createState() => _WebCheckoutFrameState();
}

class _WebCheckoutFrameState extends State<WebCheckoutFrame> {
  static int _nextViewId = 0;

  late final String _viewType;
  late final html.DivElement _containerElement;
  late final html.IFrameElement _iframeElement;

  @override
  void initState() {
    super.initState();
    _viewType = 'wallet-checkout-frame-${_nextViewId++}';
    _containerElement = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.overflow = 'hidden'
      ..style.backgroundColor = '#FFFFFF'
      ..style.pointerEvents = 'auto'
      ..style.touchAction = 'auto'
      ..style.position = 'relative';

    _iframeElement = html.IFrameElement()
      ..src = widget.checkoutUrl
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.pointerEvents = 'auto'
      ..style.touchAction = 'auto'
      ..style.backgroundColor = '#FFFFFF'
      ..style.position = 'relative'
      ..allow = 'payment *; fullscreen *';

    _iframeElement.setAttribute('tabindex', '0');
    _iframeElement.setAttribute('scrolling', 'yes');

    _containerElement.children.add(_iframeElement);
    _containerElement.onMouseDown.listen((_) => _iframeElement.focus());
    _containerElement.onTouchStart.listen((_) => _iframeElement.focus());

    _iframeElement.onLoad.listen((_) {
      widget.onPageLoaded?.call(_resolveCurrentFrameUrl());
    });

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _containerElement,
    );
  }

  @override
  void didUpdateWidget(covariant WebCheckoutFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checkoutUrl != widget.checkoutUrl) {
      _iframeElement.src = widget.checkoutUrl;
    }
  }

  String _resolveCurrentFrameUrl() {
    try {
      final href = _iframeElement.contentWindow?.location.toString();
      if (href != null && href.isNotEmpty) {
        return href;
      }
    } catch (_) {
      // Cross-origin page; fall back to iframe src.
    }

    return _iframeElement.src ?? widget.checkoutUrl;
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}