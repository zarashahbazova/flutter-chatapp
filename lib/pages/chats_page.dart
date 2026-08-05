import 'package:flutter/material.dart';

class ChatsPage extends StatelessWidget {
  final String userName;

  const ChatsPage({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
      ),

      body: const Center(
        child: Text("Sohbet burada olacak"),
      ),
    );
  }
}