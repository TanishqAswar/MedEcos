import 'package:flutter/material.dart';
import '../../features/support/screens/about_us_screen.dart';
import '../theme/app_colors.dart';

class MedEcosAppBarTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final Color? textColor;

  const MedEcosAppBarTitle({
    super.key,
    required this.title,
    this.style,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: 'About MedEcos',
          child: InkWell(
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const AboutUsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/Icon.jpeg',
                height: 28,
                width: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: style ?? TextStyle(
              color: textColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
