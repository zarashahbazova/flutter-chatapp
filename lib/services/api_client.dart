import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = "http://192.168.60.48:3000";

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

  // PROFİL FOTOĞRAFI YÜKLEME (MULTIPART)
  Future<http.Response> updateProfilePhoto({
    required String token,
    required String filePath,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/profile/photo");
    var request = http.MultipartRequest("PUT", uri);

    request.headers["Authorization"] = "Bearer $token";
    request.files.add(await http.MultipartFile.fromPath('photo', filePath));

    var streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  // AUTH ENDPOINTS
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

  // CHAT ENDPOINTS
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

  Future<http.Response> searchUsers({
    required String token,
    required String query,
    required int currentUserId,
  }) {
    return get(
      url: "chat/search-users",
      token: token,
      queryParameters: {"query": query, "current_user_id": currentUserId},
    );
  }

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
      body: {"user_id": userId, "room_id": roomId},
    );
  }

  // FOTOĞRAFLI MESAJ GÖNDERME
  Future<http.Response> sendImageMessage({
    required String token,
    required int senderId,
    required int roomId,
    required String filePath,
    String? message,
  }) async {
    final uri = Uri.parse("$baseUrl/chat/message");
    var request = http.MultipartRequest("POST", uri);

    request.headers["Authorization"] = "Bearer $token";
    request.fields["sender_id"] = senderId.toString();
    request.fields["room_id"] = roomId.toString();
    if (message != null && message.isNotEmpty) {
      request.fields["message"] = message;
    }

    request.files.add(await http.MultipartFile.fromPath('image', filePath));

    var streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  // GRUP BİLGİLERİNİ GÜNCELLEME
  Future<http.Response> editGroup({
    required String token,
    required int roomId,
    required int adminId,
    required String roomName,
    String? roomDesc,
  }) async {
    return await put(
      url: 'chat/edit-group',
      token: token,
      body: {
        'room_id': roomId,
        'admin_id': adminId,
        'room_name': roomName,
        'room_desc': roomDesc ?? '',
      },
    );
  }

  // GRUP FOTOĞRAFI DÜZENLEME
  Future<http.StreamedResponse> editGroupImage({
    required String token,
    required int roomId,
    required int adminId,
    required String filePath,
  }) async {
    final url = Uri.parse('$baseUrl/chat/edit-group-image');
    var request = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['room_id'] = roomId.toString()
      ..fields['admin_id'] = adminId.toString()
      ..files.add(await http.MultipartFile.fromPath('image', filePath));

    return await request.send();
  }

  // GRUBA ÜYE EKLEME METODU (DÜZELTİLDİ: post YARDIMCI METODU KULLANILIYOR)
  Future<http.Response> addGroupParticipant({
    required String token,
    required int roomId,
    required int adminId,
    required String username,
  }) async {
    return await post(
      url: 'chat/add-participant',
      token: token,
      body: {
        'room_id': roomId,
        'admin_id': adminId,
        'username': username,
      },
    );
  }

  // GRUPTAN AYRILMA METODU
  Future<http.Response> leaveGroup({
    required String token,
    required int roomId,
    required int userId,
  }) async {
    return await put(
      url: 'chat/leave-group',
      token: token,
      body: {
        'room_id': roomId,
        'user_id': userId,
      },
    );
  }

  // GRUP ÜYESİ ÇIKARMA METODU (DÜZELTİLDİ: put YARDIMCI METODU KULLANILIYOR)
  Future<http.Response> editGroupMembers({
    required String token,
    required int roomId,
    required int adminId,
    required int participantId,
  }) async {
    return await put(
      url: 'chat/edit-group-members',
      token: token,
      body: {
        'room_id': roomId,
        'admin_id': adminId,
        'participant_id': participantId,
      },
    );
  }
}