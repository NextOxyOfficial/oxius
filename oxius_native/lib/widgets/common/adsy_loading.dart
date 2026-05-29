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
  material.RefreshIndicatorStatus? _status;
  bool _feedbackSent = false;

  Future<void> _handleRefresh() async {
    await _playRefreshFeedback();
    await widget.onRefresh();
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

  void _handleStatusChange(material.RefreshIndicatorStatus? status) {
    if (!mounted) return;
    setState(() => _status = status);

    if (status == material.RefreshIndicatorStatus.armed ||
        status == material.RefreshIndicatorStatus.refresh) {
      _playRefreshFeedback();
    }

    if (status == null || status == material.RefreshIndicatorStatus.done) {
      _feedbackSent = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _status == material.RefreshIndicatorStatus.drag ||
        _status == material.RefreshIndicatorStatus.armed ||
        _status == material.RefreshIndicatorStatus.refresh;
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final topOffset = widget.edgeOffset + 10;
    final contentOffset = visible ? widget.displacement + 22 : 0.0;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, contentOffset, 0),
          child: material.RefreshIndicator.noSpinner(
            onRefresh: _handleRefresh,
            onStatusChange: _handleStatusChange,
            triggerMode: widget.triggerMode,
            notificationPredicate: widget.notificationPredicate,
            semanticsLabel: widget.semanticsLabel,
            semanticsValue: widget.semanticsValue,
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
                    child: AdsyLoadingIndicator(
                      size: 28,
                      color: color,
                      strokeWidth: 2.6,
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
