import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';

class LeadConversionChart extends StatelessWidget {
  final int converted;
  final int lost;
  final int pending;

  const LeadConversionChart({
    super.key,
    required this.converted,
    required this.lost,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final total = converted + lost + pending;
    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No lead data',
            style: TextStyle(color: AppColors.textSecondary, fontSize: AppDimens.fontSm),
          ),
        ),
      );
    }
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 44,
          sections: [
            PieChartSectionData(
              value: converted.toDouble(),
              color: AppColors.success,
              title: '${(converted / total * 100).toStringAsFixed(0)}%',
              radius: 48,
              titleStyle: const TextStyle(
                fontSize: AppDimens.fontSm,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: lost.toDouble(),
              color: AppColors.error,
              title: '${(lost / total * 100).toStringAsFixed(0)}%',
              radius: 48,
              titleStyle: const TextStyle(
                fontSize: AppDimens.fontSm,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: pending.toDouble(),
              color: AppColors.warning,
              title: '${(pending / total * 100).toStringAsFixed(0)}%',
              radius: 48,
              titleStyle: const TextStyle(
                fontSize: AppDimens.fontSm,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
