import 'package:flutter/material.dart';

class FloatingBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FloatingBottomNav> createState() => _FloatingBottomNavState();
}

class _FloatingBottomNavState extends State<FloatingBottomNav> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.sports_tennis,
              label: 'MATCH',
              index: 0,
              isSelected: widget.currentIndex == 0,
            ),
            const SizedBox(width: 8),
            _buildNavItem(
              icon: Icons.calendar_today,
              label: 'BOOKING',
              index: 1,
              isSelected: widget.currentIndex == 1,
            ),
            const SizedBox(width: 8),
            _buildNavItem(
              icon: Icons.person,
              label: 'PERFIL',
              index: 2,
              isSelected: widget.currentIndex == 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              transform: Matrix4.identity()..scale(isSelected ? 1.1 : 1.0),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF60519b) : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: TextStyle(
                color: isSelected ? const Color(0xFF60519b) : Colors.grey,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                fontFamily: 'MonumentExtended',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
