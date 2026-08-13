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

        if (token == null || user == null) {
          throw Exception("Backend token veya kullanıcı bilgisi göndermedi.");
        }

        final userId = user["id"] is int
            ? user["id"]
            : int.parse(user["id"].toString());

        await prefs.setString("token", token);
        await prefs.setInt("userId", userId);
        await prefs.setString("userName", user["user_name"]);
        await prefs.setString("fullName", user["full_name"]);
        await prefs.setString("email", user["email"]);

        try {
          String? fcmToken;

          if (Theme.of(context).platform == TargetPlatform.iOS) {
            final apnsToken = await FirebaseMessaging.instance.getAPNSToken();

            print("LOGIN APNS TOKEN: $apnsToken");

            if (apnsToken != null) {
              fcmToken = await FirebaseMessaging.instance.getToken();
            }
          } else {
            fcmToken = await FirebaseMessaging.instance.getToken();
          }

          print("LOGIN FCM TOKEN: $fcmToken");

          if (fcmToken != null) {
            await api.updateFcmToken(token: token, fcmToken: fcmToken);
          }
        } catch (e) {
          print("FCM token alınamadı: $e");
        }

        if (!mounted) return;

        AppTheme.showSnackBar(
          context,
          message: "Giriş başarılı.",
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
    // Üst alanın rengini değiştirmek isterseniz buraya istediğiniz rengi verebilirsiniz.
    final Color topHeaderColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: topHeaderColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- ÜST ALAN (Büyütülmüş Logo Alanı) ---
            Expanded(
              flex: 3, // Üst alanın ekrandaki yüksekliğini artırdık
              child: Center(
                child: Container(
                  height: 210, // Logonun yüksekliği büyütüldü (Eski değer: 110)
                  width: 210,  // Logonun genişliği büyütüldü (Eski değer: 110)
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain, // Logoyu çerçeveye sığdırır
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 100, // Yüklenemeyen ikon da büyütüldü
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // --- ALT ALAN (Kavisli Form Kartı) ---
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 36,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Giriş Yapın",
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Devam etmek için bilgilerinizi girin.",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 28),

                        // KULLANICI ADI
                        TextFormField(
                          controller: _usernameController,
                          validator: _validateUsername,
                          decoration: const InputDecoration(
                            labelText: "Kullanıcı Adı",
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ŞİFRE
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
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // GİRİŞ BUTONU
                        ElevatedButton(
                          onPressed: _login,
                          child: const Text("Giriş Yap"),
                        ),

                        const SizedBox(height: 16),

                        // REGISTER LİNKİ
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
          ],
        ),
      ),
    );
  }
}