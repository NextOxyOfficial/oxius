import 'package:flutter/material.dart';

/// Reusable skeleton loader widgets for consistent loading states
class SkeletonLoader {
  /// Basic skeleton box
  static Widget box({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }

  /// Circular skeleton (for avatars)
  static Widget circle({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  /// List item skeleton
  static Widget listItem({
    bool showAvatar = true,
    int lineCount = 2,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            circle(size: 48),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(width: double.infinity, height: 14),
                ...List.generate(lineCount - 1, (index) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      box(
                        width: index == lineCount - 2 ? 150.0 : double.infinity,
                        height: 12,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card skeleton
  static Widget card({
    double? height,
    bool showImage = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                box(width: double.infinity, height: 12),
                const SizedBox(height: 6),
                box(width: 200, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Post skeleton
  static Widget post() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              circle(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(width: double.infinity, height: 12),
                    const SizedBox(height: 6),
                    box(width: 80, height: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          box(width: double.infinity, height: 12),
          const SizedBox(height: 6),
          box(width: double.infinity, height: 12),
          const SizedBox(height: 6),
          box(width: 200, height: 12),
        ],
      ),
    );
  }

  /// Grid item skeleton
  static Widget gridItem() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(width: double.infinity, height: 12),
                const SizedBox(height: 6),
                box(width: 80, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Full page list skeleton
  static Widget listView({
    int itemCount = 8,
    bool showAvatar = true,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => listItem(showAvatar: showAvatar),
    );
  }

  /// Full page grid skeleton
  static Widget gridView({
    int itemCount = 6,
    int crossAxisCount = 2,
    EdgeInsets? padding,
  }) {
    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => gridItem(),
    );
  }

  /// Detail page skeleton
  static Widget detailPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          box(width: double.infinity, height: 20),
          const SizedBox(height: 12),
          // Subtitle
          box(width: 200, height: 14),
          const SizedBox(height: 16),
          // Content lines
          ...List.generate(5, (index) {
            return Column(
              children: [
                box(
                  width: index == 4 ? 150.0 : double.infinity,
                  height: 12,
                ),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }
}
