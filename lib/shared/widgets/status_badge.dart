import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'OPEN':
      case 'ACCEPTED':
      case 'COMPLETED':
        return AppColors.brand500;
      case 'PENDING':
        return AppColors.warning;
      case 'REJECTED':
      case 'WITHDRAWN':
        return AppColors.error;
      case 'CLOSED':
        return AppColors.inkMuted;
      default:
        return AppColors.inkMuted;
    }
  }

  String get _label {
    const map = {
      'OPEN': 'Ouverte',
      'CLOSED': 'Fermée',
      'PENDING': 'En attente',
      'ACCEPTED': 'Acceptée',
      'REJECTED': 'Refusée',
      'WITHDRAWN': 'Retirée',
      'COMPLETED': 'Terminée',
    };
    return map[status.toUpperCase()] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
