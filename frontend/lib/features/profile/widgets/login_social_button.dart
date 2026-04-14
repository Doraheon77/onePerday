import 'package:flutter/material.dart';

class LoginSocialButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onPressed;
  final Color textColor;
  final bool border;

  const LoginSocialButton({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.onPressed,
    this.textColor = Colors.white,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey[200] : color,
          elevation: 0,
          side: border
              ? BorderSide(
                  color: isDisabled
                      ? Colors.grey.shade200
                      : Colors.grey.shade300,
                )
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isDisabled ? Colors.grey[400] : textColor),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: isDisabled ? Colors.grey[400] : textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
