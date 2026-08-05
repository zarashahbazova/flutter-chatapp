import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = "http://192.168.60.44:3000";

  Future<http.Response> post({ //login register
    required String url,
    required Map<String, dynamic> body,
  }) {
    return http.post( //backendden gelen cevap
      Uri.parse("$baseUrl/$url"),
      headers: {"Content-Type": "application/json"}, 
      body: jsonEncode(body),
    );
  }

  Future<http.Response> get({required String url, String? token}) { //profil bilgilerini cekmek
    return http.get(
      Uri.parse("$baseUrl/$url"),
      headers: {
        "Content-Type": "application/json", //bossa json belirt sadece
        if (token != null) "Authorization": "Bearer $token", //token bos degilse headera auth satiri da ekle
      },
    );
  }

  Future<http.Response> put({ //profil güncelleme
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
}
