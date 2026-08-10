import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = "http://192.168.60.34:3000";

  Future<http.Response> post({
    required String url,
    required Map<String, dynamic> body,
    String? token,
  }) {
    return http.post(
      Uri.parse("$baseUrl/$url"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> get({
    required String url,
    Map<String, dynamic>? queryParameters,
    String? token,
  }) {
    final uri = Uri.parse("$baseUrl/$url").replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );

    return http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );
  }

  Future<http.Response> put({
    required String url,
    required Map<String, dynamic> body,
    String? token,
  }) {
    return http.put(
      Uri.parse("$baseUrl/$url"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
  }

  // AUTH
  Future<http.Response> login(Map<String, dynamic> body) {
    return post(url: "auth/login", body: body);
  }

  Future<http.Response> register(Map<String, dynamic> body) {
    return post(url: "auth/register", body: body);
  }

  Future<http.Response> profile(String token) {
    return get(url: "auth/profile", token: token);
  }

  Future<http.Response> updateProfile({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return put(url: "auth/profile", token: token, body: body);
  }

  Future<http.Response> updateFcmToken({
    required String token,
    required String fcmToken,
  }) {
    return put(
      url: "auth/fcm-token",
      token: token,
      body: {"fcm_token": fcmToken},
    );
  }

  // CHAT
  Future<http.Response> rooms({required String token, required int userId}) {
    return get(
      url: "chat/rooms",
      token: token,
      queryParameters: {"user_id": userId},
    );
  }

  Future<http.Response> createRoom({
    required String token,
    required int user1Id,
    required int user2Id,
  }) {
    return post(
      url: "chat/getOrCreateRoom",
      token: token,
      body: {"user1_id": user1Id, "user2_id": user2Id},
    );
  }

  Future<http.Response> messages({
    required String token,
    required int roomId,
    required int userId,
  }) {
    return get(
      url: "chat/show-messages",
      token: token,
      queryParameters: {"room_id": roomId, "user_id": userId},
    );
  }

  Future<http.Response> sendMessage({
    required String token,
    required int senderId,
    required int roomId,
    required String message,
  }) {
    return post(
      url: "chat/message",
      token: token,
      body: {"sender_id": senderId, "room_id": roomId, "message": message},
    );
  }

  // KİŞİSEL SOHBET OLUŞTURMA (USERNAME İLE)
  Future<http.Response> createRoomByUsername({
    required String token,
    required int myUserId,
    required String targetUsername,
  }) {
    return post(
      url: "chat/getOrCreateRoom",
      token: token,
      body: {"user1_id": myUserId, "target_username": targetUsername},
    );
  }

  // KULLANICI ARAMA / ÖNERİ METODU
Future<http.Response> searchUsers({
    required String token,
    required String query,
    required int currentUserId,
  }) {
    return get(
      url: "chat/search-users",
      token: token,
      queryParameters: {
        "query": query,
        "current_user_id": currentUserId,
      },
    );
  }

  // GRUP OLUŞTURMA
Future<http.Response> createGroup({
  required String token,
  required int adminId,
  required String roomName,
  required List<String> participantUsernames,
}) {

  return post(
    url: "chat/getOrCreateGroup",
    token: token,
    body: {
      "admin_id": adminId,
      "room_name": roomName,
      "participant_usernames": participantUsernames,
    },
  );
}

Future<http.Response> markAsRead({
    required String token,
    required int userId,
    required int roomId,
  }) {
    return post(
      url: "chat/markAsRead",
      token: token,
      body: {
        "user_id": userId,
        "room_id": roomId,
      },
    );
  }}