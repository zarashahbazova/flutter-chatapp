import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _verified = false;

  final ApiClient api = ApiClient();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "E-posta giriniz.";
    }

    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    if (!regex.hasMatch(value.trim())) {
      return "Geçerli bir e-posta giriniz.";
    }

    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Kullanıcı adı giriniz.";
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Şifre giriniz.";
    }

    if (value.length < 6) {
      return "En az 6 karakter olmalıdır.";
    }

    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return "En az bir büyük harf içermelidir.";
    }

    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return "En az bir küçük harf içermelidir.";
    }

    if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
      return "En az bir rakam içermelidir.";
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Şifreyi tekrar giriniz.";
    }

    if (value != _passwordController.text) {
      return "Şifreler uyuşmuyor.";
    }

    return null;
  }

  Future<void> _verifyUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await api.post(
        url: "auth/verify-user",
        body: {
          "username": _usernameController.text.trim(),
          "email": _emailController.text.trim(),
        },
      );
      print(response.statusCode);
      print(response.body);

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _verified = true;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Kullanıcı doğrulandı.")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["error"])));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await api.put(
        url: "auth/check-user",
        body: {
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["message"])));

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["error"])));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Şifre Sıfırla")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Kayıtlı e-posta adresinizi giriniz.",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                validator: _validateUsername,
                decoration: const InputDecoration(
                  labelText: "Kullanıcı adı",
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                decoration: const InputDecoration(
                  labelText: "E-posta",
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              if (_verified) ...[
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: _validatePassword,
                  decoration: const InputDecoration(
                    labelText: "Yeni Şifre",
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: _validateConfirmPassword,
                  decoration: const InputDecoration(
                    labelText: "Şifre Tekrar",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verified ? _changePassword : _verifyUser,
                  child: Text(
                    _verified ? "Şifreyi Güncelle" : "Kullanıcıyı Doğrula",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
