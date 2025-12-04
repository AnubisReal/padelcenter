import 'package:flutter/material.dart';

class SettingsButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;

  const SettingsButton({super.key, required this.onPressed, this.size = 45});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: () {
            print('SettingsButton tapped!');
            onPressed();
          },
          child: Icon(
            Icons.settings,
            color: Colors.white.withOpacity(0.8),
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
