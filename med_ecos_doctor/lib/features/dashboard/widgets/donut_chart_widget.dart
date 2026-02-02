import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';

class DonutChartWidget extends StatelessWidget {
  final Map<String, int> data;

  const DonutChartWidget({
    super.key,
    required this.data,
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
            'Patients Summarey December 2021',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: Row(
              children: [
                // Donut Chart
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 60,
                      sections: _buildSections(),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Legend
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('New Patients', AppColors.chartLightBlue),
                      const SizedBox(height: 12),
                      _buildLegendItem('Old Patients', AppColors.chartOrange),
                      const SizedBox(height: 12),
                      _buildLegendItem('Total Patients', AppColors.chartBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final newPatients = data['New Patients'] ?? 0;
    final oldPatients = data['Old Patients'] ?? 0;
    final totalPatients = data['Total Patients'] ?? 0;

    return [
      PieChartSectionData(
        color: AppColors.chartBlue,
        value: totalPatients.toDouble(),
        title: '',
        radius: 40,
      ),
      PieChartSectionData(
        color: AppColors.chartOrange,
        value: oldPatients.toDouble(),
        title: '',
        radius: 40,
      ),
      PieChartSectionData(
        color: AppColors.chartLightBlue,
        value: newPatients.toDouble(),
        title: '',
        radius: 40,
      ),
    ];
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
