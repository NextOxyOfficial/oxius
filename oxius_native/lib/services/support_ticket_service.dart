import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/support_ticket_models.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

class SupportTicketService {
  /// Get all support tickets for the current user
  static Future<List<SupportTicket>> getTickets() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(ApiService.getApiUrl('tickets/')),
        headers: headers,
      );

      debugPrint('=== Get Support Tickets ===');
      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> ticketsJson = data is List ? data : (data['results'] ?? []);
        
        return ticketsJson
            .map((json) => SupportTicket.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting support tickets: $e');
      return [];
    }
  }

  /// Get a single support ticket with all replies
  static Future<SupportTicket?> getTicketDetail(String ticketId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(ApiService.getApiUrl('tickets/$ticketId/')),
        headers: headers,
      );

      debugPrint('=== Get Ticket Detail ===');
      debugPrint('Ticket ID: $ticketId');
      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SupportTicket.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting ticket detail: $e');
      return null;
    }
  }

  /// Create a new support ticket
  static Future<SupportTicket?> createTicket({
    required String title,
    required String message,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse(ApiService.getApiUrl('tickets/')),
        headers: headers,
        body: json.encode({
          'title': title,
          'message': message,
        }),
      );

      debugPrint('=== Create Support Ticket ===');
      debugPrint('Title: $title');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return SupportTicket.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('Error creating support ticket: $e');
      return null;
    }
  }

  /// Add a reply to a support ticket
  static Future<TicketReply?> addReply({
    required String ticketId,
    required String message,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse(ApiService.getApiUrl('tickets/$ticketId/replies/')),
        headers: headers,
        body: json.encode({
          'message': message,
        }),
      );

      debugPrint('=== Add Ticket Reply ===');
      debugPrint('Ticket ID: $ticketId');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return TicketReply.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('Error adding ticket reply: $e');
      return null;
    }
  }

  /// Update ticket status (only users can close resolved tickets)
  static Future<bool> updateTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse(ApiService.getApiUrl('tickets/$ticketId/status/')),
        headers: headers,
        body: json.encode({
          'status': status,
        }),
      );

      debugPrint('=== Update Ticket Status ===');
      debugPrint('Ticket ID: $ticketId');
      debugPrint('New Status: $status');
      debugPrint('Response Status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating ticket status: $e');
      return false;
    }
  }

  /// Mark ticket as read
  static Future<bool> markTicketAsRead(String ticketId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse(ApiService.getApiUrl('tickets/$ticketId/mark-read/')),
        headers: headers,
      );

      debugPrint('=== Mark Ticket as Read ===');
      debugPrint('Ticket ID: $ticketId');
      debugPrint('Status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking ticket as read: $e');
      return false;
    }
  }
}
