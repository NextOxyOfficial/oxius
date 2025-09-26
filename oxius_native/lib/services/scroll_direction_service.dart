import 'package:flutter/material.dart';

class ScrollDirectionService extends ChangeNotifier {
  static final ScrollDirectionService _instance = ScrollDirectionService._internal();
  factory ScrollDirectionService() => _instance;
  ScrollDirectionService._internal();

  bool _isScrollingDown = false;
  bool _isVisible = true;
  ScrollController? _scrollController;
  double _lastScrollPosition = 0;
  static const double _scrollThreshold = 10.0;

  bool get isScrollingDown => _isScrollingDown;
  bool get isVisible => _isVisible;

  void initialize(ScrollController scrollController) {
    _scrollController = scrollController;
    _scrollController?.addListener(_onScroll);
  }

  void dispose() {
    _scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController == null) return;

    final currentScrollPosition = _scrollController!.position.pixels;
    final scrollDelta = currentScrollPosition - _lastScrollPosition;

    // Only trigger changes if scroll delta is significant enough
    if (scrollDelta.abs() > _scrollThreshold) {
      final newIsScrollingDown = scrollDelta > 0;
      final newIsVisible = !newIsScrollingDown || currentScrollPosition <= 100;

      if (newIsScrollingDown != _isScrollingDown || newIsVisible != _isVisible) {
        _isScrollingDown = newIsScrollingDown;
        _isVisible = newIsVisible;
        _lastScrollPosition = currentScrollPosition;
        notifyListeners();
      }
    }
  }

  void forceShow() {
    if (!_isVisible) {
      _isVisible = true;
      _isScrollingDown = false;
      notifyListeners();
    }
  }

  void forceHide() {
    if (_isVisible) {
      _isVisible = false;
      _isScrollingDown = true;
      notifyListeners();
    }
  }
}