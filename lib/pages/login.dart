import 'package:Lafla/pages/forgot_password.dart';
import 'package:flutter/material.dart';
import 'package:Lafla/pages/messages_page.dart';
import 'package:Lafla/themes/tema1.dart';
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
  bool _isLoggingIn = false;
  bool _rememberMe = false;

  Future<void> _loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUsername = prefs.getString("savedUsername");
    final savedPassword = prefs.getString("savedPassword");

    if (!mounted) return;

    setState(() {
      if (savedUsername != null) {
        _usernameController.text = savedUsername;
      }
      if (savedPassword != null) {
        _passwordController.text = savedPassword;
      }
      _rememberMe = savedUsername != null && savedPassword != null;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSavedLogin();
  }

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
    if (_isLoggingIn) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoggingIn = true);

    try {
      final response = await api.login({
        "user_name": _usernameController.text.trim(),
        "password": _passwordController.text,
      });

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

        if (_rememberMe) {
          await prefs.setString("savedUsername", _usernameController.text.trim());
          await prefs.setString("savedPassword", _passwordController.text);
        } else {
          await prefs.remove("savedUsername");
          await prefs.remove("savedPassword");
        }

        try {
          String? fcmToken;
          if (Theme.of(context).platform == TargetPlatform.iOS) {
            final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            if (apnsToken != null) {
              fcmToken = await FirebaseMessaging.instance.getToken();
            }
          } else {
            fcmToken = await FirebaseMessaging.instance.getToken();
          }
          if (fcmToken != null) {
            await api.updateFcmToken(token: token, fcmToken: fcmToken);
          }
        } catch (_) {}

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
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color topHeaderColor = AppTheme.brandColor;

    return Scaffold(
      backgroundColor: topHeaderColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  height: 210,
                  width: 210,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 150,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
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
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
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
                        TextFormField(
                          controller: _usernameController,
                          validator: _validateUsername,
                          decoration: const InputDecoration(
                            labelText: "Kullanıcı Adı",
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                const Text("Beni Hatırla"),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: const Text("Şifreni mi unuttun?"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Mor Renkli Login Butonu
                        ElevatedButton(
                          style: AppTheme.loginButtonStyle(context),
                          onPressed: _isLoggingIn ? null : _login,
                          child: _isLoggingIn
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Giriş Yap"),
                        ),
                        const SizedBox(height: 16),
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