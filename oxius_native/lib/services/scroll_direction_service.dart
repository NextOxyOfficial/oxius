import 'package:flutter/material.dart';

class ScrollDirectionService extends ChangeNotifier {
  bool _isScrollingDown = false;
  bool _isVisible = true;
  ScrollController? _scrollController;
  double _lastScrollPosition = 0;
  static const double _scrollThreshold = 10.0;
  bool _disposed = false;

  bool get isScrollingDown => _isScrollingDown;
  bool get isVisible => _isVisible;
  bool get isDisposed => _disposed;

  void initialize(ScrollController scrollController) {
    if (_disposed) return;
    
    // Clean up previous controller if exists
    if (_scrollController != null && _scrollController != scrollController) {
      _scrollController!.removeListener(_onScroll);
    }
    
    _scrollController = scrollController;
    
    // Only add listener if the controller has clients (is attached to a scroll view)
    if (_scrollController!.hasClients) {
      _scrollController!.addListener(_onScroll);
      _lastScrollPosition = _scrollController!.position.pixels;
    } else {
      // Wait for the controller to be attached
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed && _scrollController != null && _scrollController!.hasClients) {
          _scrollController!.addListener(_onScroll);
          _lastScrollPosition = _scrollController!.position.pixels;
        }
      });
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    
    _disposed = true;
    _scrollController?.removeListener(_onScroll);
    _scrollController = null;
    super.dispose();
  }

  void _onScroll() {
    if (_disposed || _scrollController == null || !_scrollController!.hasClients) return;

    try {
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
          
          if (!_disposed) {
            notifyListeners();
          }
        }
      }
    } catch (e) {
      // Handle scroll position access errors gracefully
      debugPrint('ScrollDirectionService: Error accessing scroll position - $e');
    }
  }

  void forceShow() {
    if (_disposed) return;
    
    if (!_isVisible) {
      _isVisible = true;
      _isScrollingDown = false;
      notifyListeners();
    }
  }

  void forceHide() {
    if (_disposed) return;
    
    if (_isVisible) {
      _isVisible = false;
      _isScrollingDown = true;
      notifyListeners();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (!_disposed) {
      super.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    if (!_disposed) {
      super.removeListener(listener);
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}