import 'package:flutter/material.dart';

class NewChatSheet extends StatelessWidget {
  final VoidCallback onSingleChatTap;
  final VoidCallback onGroupChatTap;

  const NewChatSheet({
    super.key,
    required this.onSingleChatTap,
    required this.onGroupChatTap,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF0F4F8),
                child: Icon(
                  Icons.person_add_rounded,
                  color: Color(0xFF08314D),
                ),
              ),
              title: const Text(
                "Kişisel Sohbet Başlat",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                "Kullanıcı adı veya isim arayarak sohbet edin",
              ),
              onTap: () {
                Navigator.pop(context);
                onSingleChatTap();
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF0F4F8),
                child: Icon(Icons.groups_rounded, color: Color(0xFF08314D)),
              ),
              title: const Text(
                "Yeni Grup Oluştur",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                "Birden fazla kişiyi seçerek sohbet grubu kurun",
              ),
              onTap: () {
                Navigator.pop(context);
                onGroupChatTap();
              },
            ),
          ],
        ),
      ),
    );
  }
}