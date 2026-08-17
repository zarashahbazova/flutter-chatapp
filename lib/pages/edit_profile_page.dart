import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:Lafla/services/api_client.dart';
import 'package:Lafla/themes/tema1.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll('-', '');
    if (text.length > 8) text = text.substring(0, 8);

    String formatted = "";
    for (int i = 0; i < text.length; i++) {
      formatted += text[i];
      if ((i == 1 || i == 3) && i != text.length - 1) {
        formatted += "-";
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentUsername;
  final String currentEmail;
  final String currentPhone;
  final String currentBirthDate;
  final String? currentPhotoUrl;
  final void Function(ImageSource source)? onPickPhoto;
  final Future<void> Function({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String birth_date,
  }) onSave;

  const EditProfilePage({
    super.key,
    required this.currentName,
    required this.currentUsername,
    required this.currentEmail,
    required this.currentPhone,
    required this.currentBirthDate,
    this.currentPhotoUrl,
    this.onPickPhoto,
    required this.onSave,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _usernameController = TextEditingController(text: widget.currentUsername);
    _emailController = TextEditingController(text: widget.currentEmail);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _birthDateController = TextEditingController(text: widget.currentBirthDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _showImagePickerBottomSheet() {
    if (widget.onPickPhoto == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSurfaceColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurfaceColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.getIconBg(isDark),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: AppTheme.getIconFg(isDark),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    "Kamera ile Çek",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onPickPhoto!(ImageSource.camera);
                  },
                ),
                Divider(
                  color: onSurfaceColor.withAlpha(isDark ? 16 : 10),
                  indent: 16,
                  endIndent: 16,
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.getIconBg(isDark),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: AppTheme.getIconFg(isDark),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    "Galeriden Seç",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onPickPhoto!(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final surfaceColor = AppTheme.getSurfaceColor(isDark);
    final subColor = AppTheme.getSectionHeaderColor(isDark);

    final String firstLetter = widget.currentName.isNotEmpty
        ? widget.currentName[0].toUpperCase()
        : "?";

    final String? fullPhotoUrl =
        (widget.currentPhotoUrl != null && widget.currentPhotoUrl!.isNotEmpty)
        ? "${ApiClient.baseUrl}${widget.currentPhotoUrl!.startsWith('/') ? widget.currentPhotoUrl : '/${widget.currentPhotoUrl}'}?v=${DateTime.now().millisecondsSinceEpoch}"
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Profili Düzenle",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color.fromARGB(255, 15, 14, 17) : const Color(0xFFE8E6ED),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 50 : 6),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 74,
                        height: 74,
                        color: AppTheme.getIconBg(isDark),
                        child: fullPhotoUrl != null
                            ? Image.network(
                                fullPhotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    firstLetter,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: onSurfaceColor,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  firstLetter,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: onSurfaceColor,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.currentName.isNotEmpty
                                ? widget.currentName
                                : "Profil Fotoğrafı",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: onSurfaceColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppTheme.getIconFg(isDark),
                            ),
                            label: Text(
                              "Fotoğrafı Değiştir",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF19181B),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white.withAlpha(6)
                                  : Colors.black.withAlpha(4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide(
                                color: onSurfaceColor.withAlpha(isDark ? 40 : 25),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _showImagePickerBottomSheet,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  "KİŞİSEL BİLGİLER",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: subColor,
                  ),
                ),
              ),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: onSurfaceColor),
                decoration: InputDecoration(
                  labelText: "Ad Soyad",
                  prefixIcon: Icon(Icons.person, color: subColor),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Adınızı giriniz."
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _usernameController,
                style: TextStyle(color: onSurfaceColor),
                decoration: InputDecoration(
                  labelText: "Kullanıcı Adı",
                  prefixIcon: Icon(Icons.alternate_email_rounded, color: subColor),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Kullanıcı adınızı giriniz.";
                  }
                  if (v.length < 3 || v.length > 20) {
                    return "3-20 karakter olmalıdır.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: onSurfaceColor),
                decoration: InputDecoration(
                  labelText: "E-posta",
                  prefixIcon: Icon(Icons.email, color: subColor),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "E-posta giriniz.";
                  }
                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!regex.hasMatch(v.trim())) {
                    return "Geçerli bir e-posta giriniz.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: onSurfaceColor),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: "Telefon",
                  hintText: "5xxxxxxxxx",
                  prefixIcon: Icon(Icons.phone, color: subColor),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) {
                    return "Telefon numarası 10 haneli olmalıdır.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _birthDateController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: onSurfaceColor),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  DateInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: "Doğum Tarihi",
                  hintText: "gg-aa-yyyy",
                  prefixIcon: Icon(Icons.cake, color: subColor),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  try {
                    DateFormat("dd-MM-yyyy").parseStrict(v.trim());
                  } catch (_) {
                    return "Tarih gg-aa-yyyy formatında olmalıdır.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: AppTheme.standardButtonStyle(context),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isSaving = true);
                            await widget.onSave(
                              name: _nameController.text.trim(),
                              username: _usernameController.text.trim(),
                              email: _emailController.text.trim(),
                              phone: _phoneController.text.trim(),
                              birth_date: _birthDateController.text.trim(),
                            );
                            if (mounted) Navigator.pop(context);
                          }
                        },
                  child: _isSaving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: isDark ? const Color(0xFF121114) : Colors.white,
                          ),
                        )
                      : const Text("Bilgileri Kaydet"),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}