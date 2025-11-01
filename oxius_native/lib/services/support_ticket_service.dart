import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/support_ticket_models.dart';
import 'api_service.dart';

class SupportTicketService {
  /// Get all support tickets for the current user
  static Future<List<SupportTicket>> getTickets() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(ApiService.getApiUrl('tickets/')),
        headers: headers,
      );

      print('=== Get Support Tickets ===');
      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> ticketsJson = data is List ? data : (data['results'] ?? []);
        
        return ticketsJson
            .map((json) => SupportTicket.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error getting support tickets: $e');
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

      print('=== Get Ticket Detail ===');
      print('Ticket ID: $ticketId');
      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SupportTicket.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error getting ticket detail: $e');
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

      print('=== Create Support Ticket ===');
      print('Title: $title');
      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return SupportTicket.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error creating support ticket: $e');
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

      print('=== Add Ticket Reply ===');
      print('Ticket ID: $ticketId');
      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return TicketReply.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error adding ticket reply: $e');
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

      print('=== Update Ticket Status ===');
      print('Ticket ID: $ticketId');
      print('New Status: $status');
      print('Response Status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating ticket status: $e');
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

      print('=== Mark Ticket as Read ===');
      print('Ticket ID: $ticketId');
      print('Status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking ticket as read: $e');
      return false;
    }
  }
}
