import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config.dart';
import '../models/conversation.dart';
import 'b2c_auth_service.dart';

/// Service for messaging API calls.
class MessagingService {
  final String baseUrl;

  MessagingService({String? baseUrl})
      : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Get authorization headers — uses B2C access token when available.
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      if (!kIsWeb) {
        final token = await B2CAuthService.instance.getAccessToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (_) {
      // Ignore token errors
    }

    return headers;
  }

  /// Get all conversations for a user.
  Future<ConversationListResponse> getConversations(
    String uid, {
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/conversations').replace(
      queryParameters: {
        'uid': uid,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    debugPrint('MessagingService: GET $uri');

    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to get conversations: ${response.statusCode} ${response.reasonPhrase}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ConversationListResponse.fromJson(data);
  }

  /// Get a single conversation by ID.
  Future<Conversation> getConversation(String conversationId, String uid) async {
    final uri = Uri.parse('$baseUrl/conversations/$conversationId').replace(
      queryParameters: {'uid': uid},
    );

    debugPrint('MessagingService: GET $uri');

    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to get conversation: ${response.statusCode} ${response.reasonPhrase}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Conversation.fromJson(data);
  }

  /// Get messages in a conversation.
  Future<List<Message>> getMessages(
    String conversationId,
    String uid, {
    int limit = 50,
    DateTime? before,
  }) async {
    final queryParams = <String, String>{
      'uid': uid,
      'limit': limit.toString(),
    };
    if (before != null) {
      queryParams['before'] = before.toIso8601String();
    }

    final uri = Uri.parse('$baseUrl/conversations/$conversationId/messages')
        .replace(queryParameters: queryParams);

    debugPrint('MessagingService: GET $uri');

    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to get messages: ${response.statusCode} ${response.reasonPhrase}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Upload a file attachment and return the blob URL.
  Future<String> uploadAttachment(
    String conversationId,
    String uid,
    List<int> bytes,
    String filename,
  ) async {
    final uri = Uri.parse('$baseUrl/conversations/$conversationId/attachments')
        .replace(queryParameters: {'uid': uid});

    debugPrint('MessagingService: POST attachment $uri');

    final mediaType = _mimeTypeFromFilename(filename);
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: mediaType,
      ));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode != 200) {
      throw Exception('Attachment upload failed: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['attachment_url'] as String;
  }

  /// Send a message in a conversation.
  Future<Message> sendMessage(
    String conversationId,
    String uid,
    String content, {
    String? attachmentUrl,
    String? attachmentFilename,
  }) async {
    final uri = Uri.parse('$baseUrl/conversations/$conversationId/messages')
        .replace(queryParameters: {'uid': uid});

    debugPrint('MessagingService: POST $uri');

    final body = <String, dynamic>{'content': content};
    if (attachmentUrl != null) {
      body['attachment_url'] = attachmentUrl;
    }
    if (attachmentFilename != null) {
      body['attachment_filename'] = attachmentFilename;
    }

    final headers = await _getHeaders();
    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to send message: ${response.statusCode} ${response.reasonPhrase}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Message.fromJson(data);
  }

  /// Mark all messages in a conversation as read.
  Future<void> markConversationRead(String conversationId, String uid) async {
    final uri = Uri.parse('$baseUrl/conversations/$conversationId/mark-read')
        .replace(queryParameters: {'uid': uid});

    debugPrint('MessagingService: POST $uri');

    final headers = await _getHeaders();
    final response = await http.post(uri, headers: headers).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to mark as read: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  /// Get total unread message count across all conversations.
  Future<int> getTotalUnreadCount(String uid) async {
    final uri = Uri.parse('$baseUrl/conversations/unread-count').replace(
      queryParameters: {'uid': uid},
    );

    debugPrint('MessagingService: GET $uri');

    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to get unread count: ${response.statusCode} ${response.reasonPhrase}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['total_unread'] as int? ?? 0;
  }

  static MediaType _mimeTypeFromFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    const mimeMap = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'csv': 'text/csv',
      'json': 'application/json',
      'zip': 'application/zip',
    };
    final mime = mimeMap[ext] ?? 'application/octet-stream';
    final parts = mime.split('/');
    return MediaType(parts[0], parts[1]);
  }
}
