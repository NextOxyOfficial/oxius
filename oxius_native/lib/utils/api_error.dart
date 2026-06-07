import 'dart:convert';

/// A typed error that carries the *actual* backend reason so the UI can show
/// the user exactly why an action failed (KYC pending, balance too low, a
/// validation error, etc.) instead of a generic "failed" message.
///
/// Use [ApiError.fromResponse] in services to turn any DRF/HTTP error body into
/// this, then `throw` it. Screens catch it and show [message] (and can branch
/// on [code], e.g. [isKyc]).
class ApiError implements Exception {
  ApiError(this.message, {this.code, this.statusCode, this.fields});

  /// Human-readable reason, ready to show in a SnackBar/dialog.
  final String message;

  /// Machine code from the backend when present, e.g. "kyc_verification_required".
  final String? code;

  final int? statusCode;

  /// Per-field validation errors ({field: "msg"}) when the backend returned them.
  final Map<String, String>? fields;

  bool get isKyc =>
      code == 'kyc_verification_required' ||
      message.toLowerCase().contains('kyc');

  /// Build an [ApiError] from an HTTP status + raw response body, digging the
  /// best message out of whatever shape the backend used.
  factory ApiError.fromResponse(int statusCode, String body) {
    String? code;
    Map<String, String>? fields;
    String? message;

    try {
      final decoded = body.trim().isEmpty ? null : jsonDecode(body);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        code = map['code']?.toString();
        message = _extractMessage(map);
        fields = _extractFields(map);
      } else if (decoded is String && decoded.trim().isNotEmpty) {
        message = decoded.trim();
      } else if (decoded is List && decoded.isNotEmpty) {
        message = decoded.first.toString();
      }
    } catch (_) {
      // Non-JSON body (HTML error page etc.) — keep the default.
    }

    message ??= _defaultForStatus(statusCode);
    return ApiError(message, code: code, statusCode: statusCode, fields: fields);
  }

  /// Pull the most user-friendly string out of a decoded error map. Checks the
  /// common DRF/custom keys in priority order, then falls back to the first
  /// field-level validation message.
  static String? _extractMessage(Map<String, dynamic> map) {
    // Direct string keys, in order of preference.
    for (final key in const ['message', 'error', 'detail']) {
      final v = map[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }

    // "errors" / "non_field_errors" — list, string, or nested map.
    for (final key in const ['errors', 'non_field_errors']) {
      final v = map[key];
      final m = _stringifyErrorValue(v);
      if (m != null) return m;
    }

    // Generic DRF field errors: {"field": ["msg", ...], ...}
    for (final entry in map.entries) {
      if (entry.key == 'code') continue;
      final m = _stringifyErrorValue(entry.value);
      if (m != null) return m;
    }
    return null;
  }

  static String? _stringifyErrorValue(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    if (v is List && v.isNotEmpty) return v.first.toString();
    if (v is Map && v.isNotEmpty) {
      final first = v.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first != null) return first.toString();
    }
    return null;
  }

  static Map<String, String>? _extractFields(Map<String, dynamic> map) {
    final out = <String, String>{};
    for (final entry in map.entries) {
      if (const ['message', 'error', 'detail', 'code'].contains(entry.key)) {
        continue;
      }
      final v = entry.value;
      if (v is List && v.isNotEmpty) {
        out[entry.key] = v.first.toString();
      } else if (v is String && v.trim().isNotEmpty) {
        out[entry.key] = v.trim();
      }
    }
    return out.isEmpty ? null : out;
  }

  static String _defaultForStatus(int status) {
    switch (status) {
      case 401:
        return 'Please sign in to continue.';
      case 403:
        return 'You are not allowed to do this right now.';
      case 404:
        return 'Not found.';
      case 429:
        return 'Too many requests. Please slow down and try again.';
      case >= 500:
        return 'Server error. Please try again in a moment.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => message;
}
