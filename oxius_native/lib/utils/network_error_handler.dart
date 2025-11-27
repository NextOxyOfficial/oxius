import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Professional network error handling utility
class NetworkErrorHandler {
  /// Get user-friendly error message from exception
  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    }
    
    if (error is http.ClientException) {
      return 'Connection error. Please check your internet connection.';
    }
    
    if (error is FormatException) {
      return 'Unable to process response. Please try again.';
    }
    
    if (error is TimeoutException) {
      return 'Connection timeout. Please try again.';
    }
    
    // Check if error string contains common network-related keywords
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socket') || errorString.contains('network')) {
      return 'Network connection issue. Please check your internet.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'You don\'t have permission to perform this action.';
    }
    
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Requested resource not found.';
    }
    
    if (errorString.contains('500') || errorString.contains('server error')) {
      return 'Server error. Please try again later.';
    }
    
    if (errorString.contains('503') || errorString.contains('service unavailable')) {
      return 'Service temporarily unavailable. Please try again later.';
    }
    
    // Generic error message for unknown errors
    return 'Something went wrong. Please try again.';
  }
  
  /// Show professional error snackbar
  static void showErrorSnackbar(BuildContext context, dynamic error, {
    String? customMessage,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    final message = customMessage ?? getErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
  
  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error is SocketException || error is http.ClientException) {
      return true;
    }
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') || 
           errorString.contains('network') ||
           errorString.contains('connection');
  }
  
  /// Get appropriate icon for error type
  static IconData getErrorIcon(dynamic error) {
    if (isNetworkError(error)) {
      return Icons.wifi_off_rounded;
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('401') || errorString.contains('403')) {
      return Icons.lock_rounded;
    }
    
    if (errorString.contains('404')) {
      return Icons.search_off_rounded;
    }
    
    return Icons.error_outline_rounded;
  }
}
