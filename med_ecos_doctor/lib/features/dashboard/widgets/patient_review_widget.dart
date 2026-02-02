import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PatientReviewWidget extends StatelessWidget {
  final Map<String, double> reviews;

  const PatientReviewWidget({
    super.key,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patients Review',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...reviews.entries.map((entry) => _buildReviewBar(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildReviewBar(String label, double value) {
    Color barColor;
    switch (label.toLowerCase()) {
      case 'excellent':
        barColor = AppColors.chartBlue;
        break;
      case 'great':
        barColor = AppColors.chartOrange;
        break;
      case 'good':
        barColor = AppColors.secondary;
        break;
      case 'average':
        barColor = AppColors.chartLightBlue;
        break;
      default:
        barColor = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
