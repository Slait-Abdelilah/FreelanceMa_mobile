import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/offer_model.dart';
import 'status_badge.dart';

class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool? isFavorite;
  final VoidCallback? onFavoriteToggle;
  final bool showStatus;
  final bool showAppsCount;

  const OfferCard({
    super.key,
    required this.offer,
    this.actionLabel,
    this.onAction,
    this.isFavorite,
    this.onFavoriteToggle,
    this.showStatus = false,
    this.showAppsCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.categoryLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.brand100,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      offer.budgetDisplay,
                      style: const TextStyle(
                        color: AppColors.brand700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showStatus) ...[
                    const SizedBox(height: 6),
                    StatusBadge(status: offer.status, small: true),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            offer.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (offer.requiredSkills != null && offer.requiredSkills!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: offer.requiredSkills!
                  .take(3)
                  .map((s) => _Chip(s))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (offer.deadline != null)
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM', 'fr').format(offer.deadline!),
                      style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              if (showAppsCount)
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 12, color: AppColors.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${offer.applicationsCount ?? 0} candidature${(offer.applicationsCount ?? 0) != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              const Spacer(),
              if (isFavorite != null && onFavoriteToggle != null)
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Icon(
                    isFavorite! ? Icons.bookmark : Icons.bookmark_outline,
                    size: 20,
                    color: isFavorite! ? AppColors.brand500 : AppColors.inkMuted,
                  ),
                ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.sidebarActive,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
    );
  }
}
