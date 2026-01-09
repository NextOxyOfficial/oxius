import 'package:flutter/material.dart';
import '../models/geo_location.dart';

class GeoLocationBreadcrumb extends StatelessWidget {
  final GeoLocation location;
  final VoidCallback onChange;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final Color actionColor;

  const GeoLocationBreadcrumb({
    super.key,
    required this.location,
    required this.onChange,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            color: iconColor,
            size: 16,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              location.displayLocation,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
          InkWell(
            onTap: onChange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 14, color: actionColor),
                  const SizedBox(width: 3),
                  Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: actionColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
