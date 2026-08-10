import 'package:flutter/material.dart';
import 'package:stajapp/pages/messages_page.dart';
import 'package:stajapp/themes/tema1.dart';
import 'register.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ApiClient api = ApiClient();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Kullanıcı adınızı giriniz.";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Şifrenizi giriniz.";
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await api.login({
        "user_name": _usernameController.text.trim(),
        "password": _passwordController.text,
      });
      print(response.statusCode);
      print(response.body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        final token = data["data"]?["token"];
        final user = data["data"]?["user"];
       
        final userId = user["id"] is int
            ? user["id"]
            : int.parse(user["id"].toString());
        await prefs.setInt("userId", userId);

        if (token == null) {
          throw Exception("Backend token göndermedi.");
        }
        await prefs.setString("token", token);
        await prefs.setInt("userId", user["id"]);
        await prefs.setString("userName", user["user_name"]);
        await prefs.setString("fullName", user["full_name"]);
        await prefs.setString("email", user["email"]);
        final fcmToken = await FirebaseMessaging.instance.getToken();

        print("FCM TOKEN LOGIN: $fcmToken");
        await api.updateFcmToken(token: token, fcmToken: fcmToken!);

        if (!mounted) return;

        AppTheme.showSnackBar(
          context,
          message: "Giriş başarılı, yönlendiriliyorsunuz...",
          isError: false,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MessagesPage()),
        );
      } else {
        if (!mounted) return;
        AppTheme.showSnackBar(
          context,
          message: data["error"] ?? "Giriş başarısız.",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Sunucuya bağlanılamadı.\n$e",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 140,
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Giriş Yapın",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 32,
                        ),
                  ),

                  const SizedBox(height: 40),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Devam etmek için bilgilerinizi girin.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _usernameController,
                    validator: _validateUsername,
                    decoration: const InputDecoration(
                      labelText: "Kullanıcı Adı",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: "Şifre",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: const Text("Giriş Yap"),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Hesabın yok mu?",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text("Kayıt Ol"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}