// // liquid_bottom_bar.dart

// import 'dart:ui';
// import 'package:flutter/material.dart';

// class LiquidBottomBar extends StatelessWidget {
//   const LiquidBottomBar({
//     super.key,
//     required this.currentIndex,
//     required this.onChanged,
//   });

//   final int currentIndex;
//   final ValueChanged<int> onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
//       child: Container(
//         height: 74,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(34),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.35),
//               blurRadius: 25,
//               offset: const Offset(0, 10),
//               spreadRadius: 2,
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(34),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(
//               sigmaX: 35,
//               sigmaY: 35,
//             ),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1C1C1E).withOpacity(0.75),
//                 borderRadius: BorderRadius.circular(34),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.12),
//                   width: 1,
//                 ),
//               ),
//               child: Stack(
//                 children: [
//                   _AnimatedGlassPill(
//                     currentIndex: currentIndex,
//                   ),
//                   Row(
//                     children: [
//                       _NavItem(
//                         index: 0,
//                         currentIndex: currentIndex,
//                         icon: Icons.chat_bubble_outline_rounded,
//                         selectedIcon: Icons.chat_bubble_rounded,
//                         text: "Messages",
//                         onTap: onChanged,
//                       ),
//                       _NavItem(
//                         index: 1,
//                         currentIndex: currentIndex,
//                         icon: Icons.explore_outlined,
//                         selectedIcon: Icons.explore_rounded,
//                         text: "Discover",
//                         onTap: onChanged,
//                       ),
//                       _NavItem(
//                         index: 2,
//                         currentIndex: currentIndex,
//                         icon: Icons.person_outline_rounded,
//                         selectedIcon: Icons.person_rounded,
//                         text: "Profile",
//                         onTap: onChanged,
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _AnimatedGlassPill extends StatelessWidget {
//   const _AnimatedGlassPill({
//     required this.currentIndex,
//   });

//   final int currentIndex;

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final itemWidth = constraints.maxWidth / 3;

//         return AnimatedPositioned(
//           duration: const Duration(milliseconds: 500),
//           curve: Curves.fastEaseInToSlowEaseOut,
//           left: itemWidth * currentIndex + 8,
//           top: 8,
//           child: Container(
//             width: itemWidth - 16,
//             height: 58,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(26),
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Colors.white.withOpacity(0.35),
//                   Colors.white.withOpacity(0.18),
//                   Colors.white.withOpacity(0.08),
//                 ],
//               ),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.40),
//                 width: 1,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.white.withOpacity(0.15),
//                   blurRadius: 12,
//                   spreadRadius: 0,
//                 ),
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.25),
//                   blurRadius: 18,
//                   offset: const Offset(0, 8),
//                 ),
//               ],
//             ),
//             child: Stack(
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(26),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.2),
//                       width: 1,
//                     ),
//                   ),
//                 ),
//                 Align(
//                   alignment: Alignment.topCenter,
//                   child: Container(
//                     margin: const EdgeInsets.only(top: 3),
//                     width: (itemWidth - 16) * 0.5,
//                     height: 2.5,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(50),
//                       color: Colors.white.withOpacity(0.85),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.white.withOpacity(0.5),
//                           blurRadius: 4,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Align(
//                   alignment: Alignment.bottomCenter,
//                   child: Container(
//                     margin: const EdgeInsets.only(bottom: 4),
//                     width: (itemWidth - 16) * 0.35,
//                     height: 1.5,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(50),
//                       color: Colors.white.withOpacity(0.25),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class _NavItem extends StatelessWidget {
//   const _NavItem({
//     required this.index,
//     required this.currentIndex,
//     required this.icon,
//     required this.selectedIcon,
//     required this.text,
//     required this.onTap,
//   });

//   final int index;
//   final int currentIndex;
//   final IconData icon;
//   final IconData selectedIcon;
//   final String text;
//   final ValueChanged<int> onTap;

//   bool get selected => index == currentIndex;

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: InkWell(
//         splashColor: Colors.transparent,
//         highlightColor: Colors.transparent,
//         onTap: () => onTap(index),
//         child: SizedBox(
//           height: 74,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               AnimatedSlide(
//                 duration: const Duration(milliseconds: 350),
//                 curve: Curves.easeOutCubic,
//                 offset: selected ? Offset.zero : const Offset(0, 0.1),
//                 child: AnimatedScale(
//                   duration: const Duration(milliseconds: 350),
//                   curve: Curves.easeOutCubic,
//                   scale: selected ? 1.2 : 1.0,
//                   child: Icon(
//                     selected ? selectedIcon : icon,
//                     size: 24,
//                     color: selected ? Colors.white : Colors.white54,
//                   ),
//                 ),
//               ),
//               AnimatedSize(
//                 duration: const Duration(milliseconds: 250),
//                 curve: Curves.easeOutCubic,
//                 child: selected
//                     ? Padding(
//                         padding: const EdgeInsets.only(top: 4),
//                         child: Text(
//                           text,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                             letterSpacing: -0.2,
//                           ),
//                         ),
//                       )
//                     : const SizedBox.shrink(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// liquid_bottom_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidBottomBar extends StatelessWidget {
  const LiquidBottomBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 45,
              sigmaY: 45,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF151518).withOpacity(0.55),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: Colors.white.withOpacity(0.20),
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  _AnimatedGlassPill(
                    currentIndex: currentIndex,
                  ),
                  Row(
                    children: [
                      _NavItem(
                        index: 0,
                        currentIndex: currentIndex,
                        icon: Icons.chat_bubble_outline_rounded,
                        selectedIcon: Icons.chat_bubble_rounded,
                        text: "Messages",
                        onTap: onChanged,
                      ),
                      _NavItem(
                        index: 1,
                        currentIndex: currentIndex,
                        icon: Icons.explore_outlined,
                        selectedIcon: Icons.explore_rounded,
                        text: "Discover",
                        onTap: onChanged,
                      ),
                      _NavItem(
                        index: 2,
                        currentIndex: currentIndex,
                        icon: Icons.person_outline_rounded,
                        selectedIcon: Icons.person_rounded,
                        text: "Profile",
                        onTap: onChanged,
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

class _AnimatedGlassPill extends StatelessWidget {
  const _AnimatedGlassPill({
    required this.currentIndex,
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 3;

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastEaseInToSlowEaseOut,
          left: itemWidth * currentIndex + 6,
          top: 6,
          child: Container(
            width: itemWidth - 12,
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.45),
                  Colors.white.withOpacity(0.20),
                  Colors.white.withOpacity(0.05),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.60),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Highlight Superior Glossy
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 2),
                    height: (62) * 0.45,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.65),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // White Glossy Line
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: (itemWidth - 12) * 0.55,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.9),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

                // Soft Bottom Reflection
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 3),
                    width: (itemWidth - 12) * 0.4,
                    height: 1.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.selectedIcon,
    required this.text,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String text;
  final ValueChanged<int> onTap;

  bool get selected => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () => onTap(index),
        child: SizedBox(
          height: 74,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSlide(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                offset: selected ? Offset.zero : const Offset(0, 0.12),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  scale: selected ? 1.25 : 1.0,
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: 24,
                    color: selected ? Colors.white : Colors.white60,
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}