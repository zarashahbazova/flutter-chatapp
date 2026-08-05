import 'dart:ui';

import 'package:flutter/material.dart';
import 'chats_page.dart';
import 'discover_page.dart';
import 'profile.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> users = [
    {
      "name": "",
      "message": "",
      "icon": Icons.person,
    },
    {
      "name": "",
      "message": "",
      "icon": Icons.person,
    },
    {
      "name": "",
      "message": "",
      "icon": Icons.person,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? "Mesajlar"
              : _selectedIndex == 1
                  ? "Keşfet"
                  : "Profil",
        ),
      ),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 105),
            child: _page(),
          ),

          Positioned(
            left: 14,
            right: 14,
            bottom: MediaQuery.of(context).viewPadding.bottom + 8,
            child: _glassNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _page() {
    switch (_selectedIndex) {
      case 0:
        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index];

            return ListTile(
              leading: CircleAvatar(
                child: Icon(user["icon"]),
              ),
              title: Text(user["name"]),
              subtitle: Text(user["message"]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChatsPage(userName: user["name"]),
                  ),
                );
              },
            );
          },
        );

      case 1:
        return const DiscoverPage();

      case 2:
        return const ProfilePage();

      default:
        return const SizedBox();
    }
  }

  Widget _glassNavigation() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 25,
          sigmaY: 25,
        ),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.15),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _navButton(
                index: 0,
                icon: Icons.chat_bubble_outline_rounded,
                selectedIcon: Icons.chat_bubble_rounded,
                text: "Mesajlar",
              ),

              _navButton(
                index: 1,
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                text: "Keşfet",
              ),

              _navButton(
                index: 2,
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person,
                text: "Profil",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String text,
  }) {
    final selected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(.28)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 250),
                scale: selected ? 1.18 : 1,
                child: Icon(
                  selected ? selectedIcon : icon,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// // messages_page.dart

// import 'package:flutter/material.dart';
// import 'package:stajapp/widgets/liquid_bottom_bar.dart';
// import 'liquid_bottom_bar.dart';

// class MessagesPage extends StatefulWidget {
//   const MessagesPage({super.key});

//   @override
//   State<MessagesPage> createState() => _MessagesPageState();
// }

// class _MessagesPageState extends State<MessagesPage> {
//   int _currentIndex = 0;

//   final List<Map<String, String>> _messages = const [
//     // {
//     //   'name': 'Sarah Connor',
//     //   'message': 'Are we still meeting today at 5?',
//     //   'time': '10:42 AM',
//     //   'avatar': 'https://i.pravatar.cc/150?img=1',
//     // },
//     // {
//     //   'name': 'Alex Rivera',
//     //   'message': 'The Liquid Glass UI design looks insane!',
//     //   'time': '09:15 AM',
//     //   'avatar': 'https://i.pravatar.cc/150?img=12',
//     // },
//     // {
//     //   'name': 'Tech Sync Group',
//     //   'message': 'David: Pushed the latest updates to production.',
//     //   'time': 'Yesterday',
//     //   'avatar': 'https://i.pravatar.cc/150?img=33',
//     // },
//     // {
//     //   'name': 'Elena Rostova',
//     //   'message': 'Thanks for sending over the Flutter assets.',
//     //   'time': 'Yesterday',
//     //   'avatar': 'https://i.pravatar.cc/150?img=5',
//     // },
//     // {
//     //   'name': 'Michael Scott',
//     //   'message': 'That’s what she said!',
//     //   'time': 'Monday',
//     //   'avatar': 'https://i.pravatar.cc/150?img=60',
//     // },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0D0E12),
//       extendBody: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text(
//           'Messages',
//           style: TextStyle(
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: IndexedStack(
//         index: _currentIndex,
//         children: [
//           _buildMessagesList(),
//           const Center(
//             child: Text(
//               'Discover Page',
//               style: TextStyle(color: Colors.white, fontSize: 20),
//             ),
//           ),
//           const Center(
//             child: Text(
//               'Profile Page',
//               style: TextStyle(color: Colors.white, fontSize: 20),
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: LiquidBottomBar(
//         currentIndex: _currentIndex,
//         onChanged: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//       ),
//     );
//   }

//   Widget _buildMessagesList() {
//     return ListView.separated(
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
//       itemCount: _messages.length,
//       separatorBuilder: (context, index) => const Divider(
//         color: Colors.white10,
//         height: 1,
//         indent: 64,
//       ),
//       itemBuilder: (context, index) {
//         final item = _messages[index];
//         return ListTile(
//           contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//           leading: CircleAvatar(
//             radius: 26,
//             backgroundImage: NetworkImage(item['avatar']!),
//           ),
//           title: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 item['name']!,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 16,
//                 ),
//               ),
//               Text(
//                 item['time']!,
//                 style: const TextStyle(
//                   color: Colors.white38,
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//           subtitle: Padding(
//             padding: const EdgeInsets.only(top: 4),
//             child: Text(
//               item['message']!,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 color: Colors.white70,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//           onTap: () {},
//         );
//       },
//     );
//   }
// }