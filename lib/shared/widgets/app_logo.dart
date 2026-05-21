import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 32, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(size * 0.25),
          ),
          child: Icon(
            Icons.hub_rounded,
            color: AppColors.brand500,
            size: size * 0.55,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'FreelanceMa',
            style: TextStyle(
              fontSize: size * 0.47,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
