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
        final size = (widget.size ?? boundedMax).clamp(12.0, 38.0).toDouble();

        return SizedBox(
          width: size,
          height: size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // Determinate (upload/download progress) keeps a clean arc ring.
              if (widget.value != null) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: _SweepRingPainter(
                    color: color,
                    strokeWidth: (size * 0.10).clamp(2.6, 4.4).toDouble(),
                    progress: widget.value,
                  ),
                );
              }
              // Indeterminate: 12 rounded bars in a ring with a fading trail,
              // stepped once per tick (the classic app-loading spinner).
              return CustomPaint(
                size: Size(size, size),
                painter: _DotsRingPainter(
                  color: color,
                  t: _controller.value,
                ),
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

/// The classic "spinner": [count] rounded bars arranged in a ring, each with a
/// decreasing opacity so a bright head chases a faded tail around the circle.
/// Steps discretely (one bar per tick) for the crisp tick-tick-tick look.
class _DotsRingPainter extends CustomPainter {
  final Color color;
  final double t; // 0..1 rotation phase
  static const int count = 12;

  _DotsRingPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;
    if (r <= 0) return;

    // Bar geometry scaled to the widget size.
    final barLen = r * 0.42;
    final barWidth = (r * 0.16).clamp(1.6, 5.0);
    final outer = r - barWidth * 0.6;
    final inner = outer - barLen;

    // Discrete head position so the animation "ticks".
    final head = (t * count).floor() % count;

    for (int i = 0; i < count; i++) {
      // Distance behind the head → opacity trail.
      final dist = (head - i + count) % count;
      final alpha = (1.0 - dist / count) * 0.9 + 0.08;

      final angle = (i / count) * 2 * math.pi - math.pi / 2;
      final ca = math.cos(angle);
      final sa = math.sin(angle);
      final p1 = Offset(center.dx + ca * inner, center.dy + sa * inner);
      final p2 = Offset(center.dx + ca * outer, center.dy + sa * outer);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
        ..strokeWidth = barWidth.toDouble()
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsRingPainter old) =>
      old.t != t || old.color != color;
}

/// Draws the spinner ring. Indeterminate = a comet-style sweep-gradient arc
/// (transparent tail → solid rounded head). Determinate = a faint full track
/// plus a solid progress arc from the top.
class _SweepRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double? progress;

  _SweepRingPainter({
    required this.color,
    required this.strokeWidth,
    this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (progress != null) {
      final track = Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, track);

      final arc = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        progress!.clamp(0.0, 1.0) * math.pi * 2,
        false,
        arc,
      );
      return;
    }

    // Indeterminate comet arc.
    const sweep = math.pi * 2 * 0.80;
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: sweep,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.85),
        color,
      ],
      stops: const [0.0, 0.7, 1.0],
      tileMode: TileMode.clamp,
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_SweepRingPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.progress != progress;
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
  State<AdsyRefreshIndicator> createState() => AdsyRefreshIndicatorState();
}

class AdsyRefreshIndicatorState extends State<AdsyRefreshIndicator> {
  _AdsyRefreshState _state = _AdsyRefreshState.idle;
  bool _feedbackSent = false;
  double _dragExtent = 0;

  Future<void> show() async {
    if (_state == _AdsyRefreshState.refreshing) return;

    setState(() {
      _dragExtent = _triggerPullExtent(context) + _activationPullExtent();
      _state = _AdsyRefreshState.armed;
    });

    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    await _handleRefresh();
  }

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
      final activePull = _activePullExtent(nextPull);
      final threshold = _triggerPullExtent(context);
      final nextState = activePull >= threshold
          ? _AdsyRefreshState.armed
          : activePull > 0
              ? _AdsyRefreshState.dragging
              : _AdsyRefreshState.idle;

      setState(() {
        _dragExtent = nextPull;
        _state = nextState;
      });

      if (nextState != _AdsyRefreshState.armed) {
        _feedbackSent = false;
      }
    }

    if (notification is ScrollEndNotification &&
        _state != _AdsyRefreshState.refreshing) {
      final activePull = _activePullExtent(_dragExtent);
      if (activePull <= 0 && _state != _AdsyRefreshState.armed) {
        if (_dragExtent != 0 || _state != _AdsyRefreshState.idle) {
          setState(() {
            _state = _AdsyRefreshState.idle;
            _dragExtent = 0;
            _feedbackSent = false;
          });
        }
        return false;
      }
      if (activePull >= _triggerPullExtent(context)) {
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
    return math.min(height * 0.25, 190.0);
  }

  double _triggerPullExtent(BuildContext context) {
    // Standard-feel trigger (~96px with the default displacement). The old
    // value (displacement+128, min 156, PLUS the 32px activation) demanded a
    // ~200px drag — normal pulls released below it and nothing happened,
    // which read as "pull-to-refresh is broken" on every screen using this.
    final height = MediaQuery.sizeOf(context).height;
    return math.min(
      math.max(widget.displacement + 56, 88.0),
      height * 0.20,
    );
  }

  double _activationPullExtent() {
    return 16.0;
  }

  double _activePullExtent(double rawPull) {
    return math.max(0.0, rawPull - _activationPullExtent()).toDouble();
  }

  double _rubberBandOffset(double pull, double maxRawPull) {
    if (pull <= 0) return 0;
    final normalized = (pull / maxRawPull).clamp(0.0, 1.0);
    final eased = (1 - math.pow(1 - normalized, 1.55)).toDouble();
    return _maxVisualPull(context) * eased;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final maxRawPull = _maxRawPull(context);
    final triggerPull = _triggerPullExtent(context);
    final activePull = _activePullExtent(_dragExtent);
    final visible = _state == _AdsyRefreshState.refreshing || activePull > 0.0;
    final pullProgress = (activePull / triggerPull).clamp(0.0, 1.0).toDouble();
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

    // Drag ring that fills as the user pulls (no favicon).
    return SizedBox(
      width: 28,
      height: 28,
      child: material.CircularProgressIndicator(
        value: clampedProgress <= 0 ? 0.01 : clampedProgress,
        backgroundColor: color.withValues(alpha: 0.12),
        color: color,
        strokeWidth: 2.8,
        strokeCap: StrokeCap.round,
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
