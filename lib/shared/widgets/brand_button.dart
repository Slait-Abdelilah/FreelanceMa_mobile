import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BrandButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool outline;
  final IconData? icon;
  final Color? color;

  const BrandButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.outline = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (outline ? Colors.transparent : AppColors.ink);
    final fg = outline ? AppColors.ink : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            decoration: outline
                ? BoxDecoration(
                    border: Border.all(color: AppColors.ink, width: 2),
                    borderRadius: BorderRadius.circular(100),
                  )
                : null,
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: fg, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
