import 'dart:math' as math;

import 'package:flutter/material.dart' hide RefreshIndicator;
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';

class AdsyLoadingIndicator extends StatefulWidget {
  final double? value;
  final Color? backgroundColor;
  final Color? color;
  final Animation<Color?>? valueColor;
  final double strokeWidth;
  final double strokeAlign;
  final StrokeCap? strokeCap;
  final String? semanticsLabel;
  final String? semanticsValue;
  final BoxConstraints? constraints;
  final double? size;
  final EdgeInsetsGeometry? padding;

  const AdsyLoadingIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.color,
    this.valueColor,
    this.strokeWidth = 4.0,
    this.strokeAlign = material.CircularProgressIndicator.strokeAlignCenter,
    this.strokeCap,
    this.semanticsLabel,
    this.semanticsValue,
    this.constraints,
    this.size,
    this.padding,
  });

  @override
  State<AdsyLoadingIndicator> createState() => _AdsyLoadingIndicatorState();
}

class _AdsyLoadingIndicatorState extends State<AdsyLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ??
        widget.valueColor?.value ??
        Theme.of(context).colorScheme.primary;

    Widget child = LayoutBuilder(
      builder: (context, constraints) {
        final boundedMax = math.min(
          constraints.hasBoundedWidth ? constraints.maxWidth : 42,
          constraints.hasBoundedHeight ? constraints.maxHeight : 42,
        );
        final size = (widget.size ?? boundedMax).clamp(14.0, 46.0).toDouble();
        final logoSize = (size * 0.54).clamp(12.0, 24.0).toDouble();
        final dotSize = (size * 0.12).clamp(2.2, 4.8).toDouble();

        return SizedBox(
          width: size,
          height: size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: _controller.value * math.pi * 2,
                    child: material.CircularProgressIndicator(
                      value: widget.value,
                      backgroundColor: widget.backgroundColor,
                      color: color.withValues(alpha: 0.18),
                      strokeWidth: math.max(1.4, widget.strokeWidth * 0.72),
                      strokeAlign: widget.strokeAlign,
                      strokeCap: widget.strokeCap ?? StrokeCap.round,
                      semanticsLabel: widget.semanticsLabel,
                      semanticsValue: widget.semanticsValue,
                    ),
                  ),
                  Image.asset(
                    'assets/images/favicon.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.autorenew_rounded,
                      size: logoSize,
                      color: color,
                    ),
                  ),
                  ...List.generate(3, (index) {
                    final angle =
                        (_controller.value * math.pi * 2) + (index * 2.09);
                    final radius = size * 0.38;
                    return Transform.translate(
                      offset: Offset(
                          math.cos(angle) * radius, math.sin(angle) * radius),
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: index == 0 ? 1 : (0.42 + index * 0.18),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );

    if (widget.constraints != null) {
      child = ConstrainedBox(constraints: widget.constraints!, child: child);
    }

    if (widget.padding != null) {
      child = Padding(padding: widget.padding!, child: child);
    }

    return child;
  }
}

class AdsyRefreshIndicator extends StatefulWidget {
  final Widget child;
  final RefreshCallback onRefresh;
  final double displacement;
  final double edgeOffset;
  final RefreshIndicatorTriggerMode triggerMode;
  final ScrollNotificationPredicate notificationPredicate;
  final Color? color;
  final Color? backgroundColor;
  final String? semanticsLabel;
  final String? semanticsValue;
  final double strokeWidth;
  final double elevation;

  const AdsyRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.color,
    this.backgroundColor,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeWidth = material.RefreshProgressIndicator.defaultStrokeWidth,
    this.elevation = 2.0,
  });

  @override
  State<AdsyRefreshIndicator> createState() => _AdsyRefreshIndicatorState();
}

class _AdsyRefreshIndicatorState extends State<AdsyRefreshIndicator> {
  _AdsyRefreshState _state = _AdsyRefreshState.idle;
  bool _feedbackSent = false;
  double _dragExtent = 0;

  Future<void> _handleRefresh() async {
    if (_state == _AdsyRefreshState.refreshing) return;

    setState(() => _state = _AdsyRefreshState.refreshing);
    await _playRefreshFeedback();

    try {
      await widget.onRefresh();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'adsy refresh indicator',
          context: ErrorDescription('while running pull-to-refresh'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _state = _AdsyRefreshState.settling;
          _dragExtent = 0;
          _feedbackSent = false;
        });
        await Future<void>.delayed(const Duration(milliseconds: 220));
      }
      if (mounted) {
        setState(() => _state = _AdsyRefreshState.idle);
      }
    }
  }

  Future<void> _playRefreshFeedback() async {
    if (_feedbackSent) return;
    _feedbackSent = true;

    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Haptics are best-effort.
    }

    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // System sound is best-effort.
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) {
      return false;
    }

    final atTop = notification.metrics.axis == Axis.vertical &&
        notification.metrics.pixels <= notification.metrics.minScrollExtent;

    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      if (_state != _AdsyRefreshState.refreshing) {
        setState(() {
          _state = _AdsyRefreshState.idle;
          _dragExtent = 0;
          _feedbackSent = false;
        });
      }
      return false;
    }

    if (!atTop) {
      if (_dragExtent != 0 && _state != _AdsyRefreshState.refreshing) {
        setState(() {
          _state = _AdsyRefreshState.idle;
          _dragExtent = 0;
          _feedbackSent = false;
        });
      }
      return false;
    }

    double pullDelta = 0;
    if (notification is OverscrollNotification) {
      pullDelta = -notification.overscroll;
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      final delta = notification.scrollDelta ?? 0;
      pullDelta = -delta;
    }

    if (pullDelta != 0 && _state != _AdsyRefreshState.refreshing) {
      final maxPull = _maxRawPull(context);
      final nextPull = (_dragExtent + pullDelta).clamp(0.0, maxPull);
      final threshold = _triggerPullExtent(context);
      final nextState = nextPull >= threshold
          ? _AdsyRefreshState.armed
          : _AdsyRefreshState.dragging;

      setState(() {
        _dragExtent = nextPull;
        _state = nextPull > 0 ? nextState : _AdsyRefreshState.idle;
      });

      if (nextState != _AdsyRefreshState.armed) {
        _feedbackSent = false;
      }
    }

    if (notification is ScrollEndNotification &&
        _state != _AdsyRefreshState.refreshing) {
      if (_dragExtent <= 0 && _state != _AdsyRefreshState.armed) {
        return false;
      }
      if (_dragExtent >= _triggerPullExtent(context)) {
        _handleRefresh();
      } else {
        setState(() {
          _state = _AdsyRefreshState.settling;
          _dragExtent = 0;
          _feedbackSent = false;
        });
        Future<void>.delayed(const Duration(milliseconds: 180), () {
          if (!mounted || _state != _AdsyRefreshState.settling) return;
          setState(() => _state = _AdsyRefreshState.idle);
        });
      }
    }

    return false;
  }

  double _maxRawPull(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return math.min(height * 0.52, 460.0);
  }

  double _maxVisualPull(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return math.min(height * 0.42, 280.0);
  }

  double _triggerPullExtent(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return math.min(
      math.max(widget.displacement + 128, 156.0),
      height * 0.28,
    );
  }

  double _rubberBandOffset(double pull, double maxRawPull) {
    if (pull <= 0) return 0;
    final normalized = (pull / maxRawPull).clamp(0.0, 1.0);
    final eased = (1 - math.pow(1 - normalized, 2.35)).toDouble();
    return _maxVisualPull(context) * eased;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _state != _AdsyRefreshState.idle;
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final maxRawPull = _maxRawPull(context);
    final triggerPull = _triggerPullExtent(context);
    final pullProgress = (_dragExtent / triggerPull).clamp(0.0, 1.0).toDouble();
    final refreshRestOffset = math
        .min(
          math.max(widget.displacement + 52, 84.0),
          112.0,
        )
        .toDouble();
    final contentOffset = _state == _AdsyRefreshState.refreshing
        ? refreshRestOffset
        : _rubberBandOffset(_dragExtent, maxRawPull);
    final topOffset = widget.edgeOffset +
        math
            .max(10.0, math.min(contentOffset * 0.42, refreshRestOffset))
            .toDouble();

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: AnimatedContainer(
            duration: Duration(
              milliseconds: _state == _AdsyRefreshState.dragging ||
                      _state == _AdsyRefreshState.armed
                  ? 26
                  : 220,
            ),
            curve: _state == _AdsyRefreshState.dragging ||
                    _state == _AdsyRefreshState.armed
                ? Curves.linear
                : Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, contentOffset, 0),
            child: widget.child,
          ),
        ),
        Positioned(
          top: topOffset,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: AnimatedScale(
                scale: visible ? 1 : 0.82,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (widget.backgroundColor ?? Colors.white).withValues(
                      alpha: 0.96,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _state == _AdsyRefreshState.refreshing
                        ? AdsyLoadingIndicator(
                            size: 28,
                            color: color,
                            strokeWidth: 2.6,
                          )
                        : _PullProgressIndicator(
                            progress: pullProgress,
                            color: color,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PullProgressIndicator extends StatelessWidget {
  final double progress;
  final Color color;

  const _PullProgressIndicator({
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          material.CircularProgressIndicator(
            value: clampedProgress <= 0 ? 0.01 : clampedProgress,
            backgroundColor: color.withValues(alpha: 0.12),
            color: color,
            strokeWidth: 2.6,
            strokeCap: StrokeCap.round,
          ),
          Image.asset(
            'assets/images/favicon.png',
            width: 15,
            height: 15,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.autorenew_rounded,
              size: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum _AdsyRefreshState {
  idle,
  dragging,
  armed,
  refreshing,
  settling,
}
