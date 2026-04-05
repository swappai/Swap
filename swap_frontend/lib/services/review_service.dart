import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ReviewModel {
  final String id;
  final String swapRequestId;
  final String reviewerUid;
  final String reviewedUid;
  final int rating;
  final String? reviewText;
  final String? skillExchanged;
  final double? hoursExchanged;
  final String createdAt;
  final String? reviewerName;
  final String? reviewerPhoto;

  ReviewModel({
    required this.id,
    required this.swapRequestId,
    required this.reviewerUid,
    required this.reviewedUid,
    required this.rating,
    this.reviewText,
    this.skillExchanged,
    this.hoursExchanged,
    required this.createdAt,
    this.reviewerName,
    this.reviewerPhoto,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
    id: j['id'] as String? ?? '',
    swapRequestId: j['swap_request_id'] as String? ?? '',
    reviewerUid: j['reviewer_uid'] as String? ?? '',
    reviewedUid: j['reviewed_uid'] as String? ?? '',
    rating: (j['rating'] as num?)?.toInt() ?? 0,
    reviewText: j['review_text'] as String?,
    skillExchanged: j['skill_exchanged'] as String?,
    hoursExchanged: (j['hours_exchanged'] as num?)?.toDouble(),
    createdAt: j['created_at'] as String? ?? '',
    reviewerName: j['reviewer_name'] as String?,
    reviewerPhoto: j['reviewer_photo'] as String?,
  );
}

class ReviewListResult {
  final List<ReviewModel> reviews;
  final int total;
  final double averageRating;

  ReviewListResult({
    required this.reviews,
    required this.total,
    required this.averageRating,
  });
}

class ReviewService {
  final String baseUrl;
  ReviewService({String? baseUrl})
    : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<ReviewListResult> getUserReviews(String uid, {int limit = 20, int offset = 0}) async {
    final uri = Uri.parse('$baseUrl/reviews/user/$uid?limit=$limit&offset=$offset');
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw Exception('Failed to get reviews: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final reviews = (data['reviews'] as List<dynamic>)
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return ReviewListResult(
      reviews: reviews,
      total: (data['total'] as num?)?.toInt() ?? 0,
      averageRating: (data['average_rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<ReviewModel> submitReview({
    required String reviewerUid,
    required String swapRequestId,
    required int rating,
    String? reviewText,
  }) async {
    final uri = Uri.parse('$baseUrl/reviews?uid=$reviewerUid');
    final body = jsonEncode({
      'swap_request_id': swapRequestId,
      'rating': rating,
      'review_text': reviewText,
    });

    final resp = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      throw Exception('Failed to submit review: ${resp.statusCode} ${resp.body}');
    }
    return ReviewModel.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getSwapReviews(String swapRequestId, String uid) async {
    final uri = Uri.parse('$baseUrl/reviews/swap/$swapRequestId?uid=$uid');
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw Exception('Failed to get swap reviews: ${resp.statusCode}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
