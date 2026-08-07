// import 'package:flutter/material.dart';
// import 'package:liquid_glass_bar/liquid_glass_bar.dart';

// class DiscoverPage extends StatefulWidget {
//   const DiscoverPage({super.key});

//   @override
//   State<DiscoverPage> createState() => _DiscoverPageState();
// }

// class _DiscoverPageState extends State<DiscoverPage> {
//   int _index = 1;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FCFD),
//       extendBody: true,

//       appBar: AppBar(
//         title: const Text("Keşfet"),
//       ),

//       body: const Center(
//         child: Text(
//           "2. deneme",
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),

//       bottomNavigationBar: LiquidGlassBar(
//         currentIndex: _index,
//         onTap: (i) {
//           setState(() {
//             _index = i;
//           });
//         },
//         items: const [
//           LiquidGlassBarItem(
//             iconData: Icons.chat_bubble_outline,
//             label: "Mesajlar",
//           ),
//           LiquidGlassBarItem(
//             iconData: Icons.explore,
//             label: "Keşfet",
//           ),
//           LiquidGlassBarItem(
//             iconData: Icons.person_outline,
//             label: "Profil",
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'dart:ui';
import 'package:flutter/material.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {

  int currentIndex = 1;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xffF8FCFD),
      extendBody: true,

      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [

            //---------------------------------------------------
            // Background
            //---------------------------------------------------

            Positioned.fill(
              child: Container(
                color: const Color(0xffF8FCFD),
              ),
            ),

            //---------------------------------------------------
            // Decorative lights
            //---------------------------------------------------

            Positioned(
              top: -180,
              left: -120,
              child: _lightBlob(
                size: 420,
                color: Colors.white.withValues(alpha: .95),
              ),
            ),

            Positioned(
              top: -40,
              right: -120,
              child: _lightBlob(
                size: 260,
                color: Colors.white.withValues(alpha: .55),
              ),
            ),

            Positioned(
              bottom: 220,
              left: -90,
              child: _lightBlob(
                size: 240,
                color: Colors.white.withValues(alpha: .45),
              ),
            ),

            //---------------------------------------------------
            // Page
            //---------------------------------------------------

            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 22),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [

            //       const SizedBox(height: 18),

            //       const Text(
            //         "Keşfet",
            //         style: TextStyle(
            //           fontSize: 34,
            //           fontWeight: FontWeight.w800,
            //         ),
            //       ),

            //       const SizedBox(height: 26),

            //       _glassSearch(),

            //       const SizedBox(height: 28),

            //       Expanded(
            //         child: ListView(
            //           physics: const BouncingScrollPhysics(),
            //           children: [

            //             _glassCard(
            //               title: "Yeni Kullanıcılar",
            //               subtitle:
            //                   "Sana uygun kişileri keşfetmeye başla.",
            //               icon: Icons.people_alt_rounded,
            //             ),

            //             const SizedBox(height: 18),

            //             _glassCard(
            //               title: "Gruplar",
            //               subtitle:
            //                   "İlgi alanlarına göre topluluklara katıl.",
            //               icon: Icons.groups_rounded,
            //             ),

            //             const SizedBox(height: 18),

            //             _glassCard(
            //               title: "Etkinlikler",
            //               subtitle:
            //                   "Yakınındaki etkinlikleri görüntüle.",
            //               icon: Icons.celebration_rounded,
            //             ),

            //             const SizedBox(height: 120),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // Positioned(
            //   left: 18,
            //   right: 18,
            //   bottom: MediaQuery.of(context).padding.bottom + 12,
            //   child: _liquidBar(),
            // ),
          ],
        ),
      ),
    );
    
  }

  // Widget _glassSearch() {
  //   return ClipRRect(
  //     borderRadius: BorderRadius.circular(22),
  //     child: BackdropFilter(
  //       filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
  //       child: Container(
  //         height: 62,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(22),
  //           border: Border.all(
  //             color: Colors.white.withValues(alpha: .85),
  //             width: 1.5,
  //           ),
  //           color: Colors.white.withValues(alpha: .22),
  //           gradient: LinearGradient(
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //             colors: [
  //               Colors.white.withValues(alpha: .55),
  //               Colors.white.withValues(alpha: .18),
  //               Colors.white.withValues(alpha: .05),
  //             ],
  //           ),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.white.withValues(alpha: .18),
  //               blurRadius: 35,
  //               spreadRadius: -8,
  //             ),
  //           ],
  //         ),
  //         child: const TextField(
  //           decoration: InputDecoration(
  //             border: InputBorder.none,
  //             hintText: "Keşfet...",
  //             prefixIcon: Icon(Icons.search),
  //             contentPadding: EdgeInsets.symmetric(vertical: 18),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _glassCard({
  //   required String title,
  //   required String subtitle,
  //   required IconData icon,
  // }) {
  //   return ClipRRect(
  //     borderRadius: BorderRadius.circular(34),
  //     child: BackdropFilter(
  //       filter: ImageFilter.blur(
  //         sigmaX: 30,
  //         sigmaY: 30,
  //       ),
  //       child: Container(
  //         padding: const EdgeInsets.all(22),
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(34),
  //           border: Border.all(
  //             color: Colors.white.withValues(alpha: .9),
  //             width: 1.5,
  //           ),
  //           color: Colors.white.withValues(alpha: .18),
  //           gradient: LinearGradient(
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //             colors: [

  //               Colors.white.withValues(alpha: .55),

  //               Colors.white.withValues(alpha: .20),

  //               Colors.white.withValues(alpha: .05),

  //             ],
  //           ),
  //           boxShadow: [

  //             BoxShadow(
  //               color: Colors.white.withValues(alpha: .18),
  //               blurRadius: 45,
  //               spreadRadius: -12,
  //             ),

  //             BoxShadow(
  //               color: Colors.black.withValues(alpha: .05),
  //               blurRadius: 24,
  //               offset: const Offset(0, 10),
  //             ),
  //           ],
  //         ),
  //         child: Row(
  //           children: [

  //             Container(
  //               width: 64,
  //               height: 64,
  //               decoration: BoxDecoration(
  //                 shape: BoxShape.circle,
  //                 border: Border.all(
  //                   color: Colors.white.withValues(alpha: .9),
  //                 ),
  //                 gradient: LinearGradient(
  //                   colors: [
  //                     Colors.white.withValues(alpha: .60),
  //                     Colors.white.withValues(alpha: .08),
  //                   ],
  //                 ),
  //               ),
  //               child: Icon(
  //                 icon,
  //                 size: 30,
  //               ),
  //             ),

  //             const SizedBox(width: 20),

  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [

  //                   Text(
  //                     title,
  //                     style: const TextStyle(
  //                       fontWeight: FontWeight.w700,
  //                       fontSize: 21,
  //                     ),
  //                   ),

  //                   const SizedBox(height: 6),

  //                   Text(
  //                     subtitle,
  //                     style: TextStyle(
  //                       color: Colors.grey.shade700,
  //                       fontSize: 15,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),

  //             const Icon(Icons.arrow_forward_ios_rounded),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
  // Widget _liquidBar() {
  //   const items = [
  //     Icons.chat_bubble_outline_rounded,
  //     Icons.explore_rounded,
  //     Icons.person_outline_rounded,
  //   ];

  //   return Container(
  //     height: 74,
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(38),
  //       color: Colors.white.withValues(alpha: .12),
  //       border: Border.all(
  //         color: Colors.white.withValues(alpha: .75),
  //         width: 1.2,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: .08),
  //           blurRadius: 30,
  //           offset: const Offset(0, 12),
  //         ),
  //       ],
  //     ),
  //     child: Stack(
  //       children: [

  //         // Camın üst parlama çizgisi
  //         Positioned(
  //           left: 18,
  //           right: 18,
  //           top: 8,
  //           child: Container(
  //             height: 2,
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(30),
  //               gradient: LinearGradient(
  //                 colors: [
  //                   Colors.white.withValues(alpha: .90),
  //                   Colors.white.withValues(alpha: .08),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),

  //         Row(
  //           children: List.generate(3, (index) {
  //             final selected = currentIndex == index;

  //             return Expanded(
  //               child: GestureDetector(
  //                 onTap: () {
  //                   setState(() {
  //                     currentIndex = index;
  //                   });
  //                 },
  //                 child: Center(
  //                   child: AnimatedContainer(
  //                     duration: const Duration(milliseconds: 350),
  //                     curve: Curves.easeOutCubic,
  //                     width: selected ? 92 : 60,
  //                     height: selected ? 58 : 46,
  //                     decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(28),

  //                       color: selected
  //                           ? Colors.white.withValues(alpha: .20)
  //                           : Colors.transparent,

  //                       border: selected
  //                           ? Border.all(
  //                               color: Colors.white.withValues(alpha: .92),
  //                             )
  //                           : null,

  //                       gradient: selected
  //                           ? LinearGradient(
  //                               begin: Alignment.topLeft,
  //                               end: Alignment.bottomRight,
  //                               colors: [
  //                                 Colors.white.withValues(alpha: .55),
  //                                 Colors.white.withValues(alpha: .18),
  //                                 Colors.white.withValues(alpha: .04),
  //                               ],
  //                             )
  //                           : null,

  //                       boxShadow: selected
  //                           ? [
  //                               BoxShadow(
  //                                 color: Colors.white.withValues(alpha: .20),
  //                                 blurRadius: 25,
  //                                 spreadRadius: -8,
  //                               ),
  //                               BoxShadow(
  //                                 color: Colors.black.withValues(alpha: .10),
  //                                 blurRadius: 18,
  //                                 offset: const Offset(0, 8),
  //                               ),
  //                             ]
  //                           : [],
  //                     ),

  //                     child: ClipRRect(
  //                       borderRadius: BorderRadius.circular(28),
  //                       child: BackdropFilter(
  //                         filter: ImageFilter.blur(
  //                           sigmaX: 28,
  //                           sigmaY: 28,
  //                         ),
  //                         child: Icon(
  //                           items[index],
  //                           color: Colors.black87,
  //                           size: 28,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             );
  //           }),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _lightBlob({
    required double size,
    required Color color,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            radius: .95,
            colors: [
              color,
              color.withValues(alpha: .45),
              color.withValues(alpha: .10),
              Colors.transparent,
            ],
            stops: const [
              .0,
              .35,
              .72,
              1,
            ],
          ),
        ),
      ),
    );
  }
}