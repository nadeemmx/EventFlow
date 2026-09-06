import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerLowest,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: DesignSystem.spacing4),
            _buildHeaderSkeleton(),
            const SizedBox(height: DesignSystem.spacing6),
            _buildStatsSkeleton(),
            const SizedBox(height: DesignSystem.spacing6),
            _buildScheduleSkeleton(),
            const SizedBox(height: DesignSystem.spacing6),
            _buildQuickActionsSkeleton(),
            const SizedBox(height: DesignSystem.spacing6),
            _buildBookingListSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
                  ),
                ),
                const SizedBox(height: DesignSystem.spacing2),
                Container(
                  height: 28,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: DesignSystem.spacing3,
        crossAxisSpacing: DesignSystem.spacing3,
        childAspectRatio: 1.6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(4, (_) => _skeletonCard()),
      ),
    );
  }

  Widget _buildScheduleSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
            ),
          ),
          const SizedBox(height: DesignSystem.spacing3),
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
            ),
          ),
          const SizedBox(height: DesignSystem.spacing3),
          Row(
            children: List.generate(4, (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingListSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14,
            width: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
            ),
          ),
          const SizedBox(height: DesignSystem.spacing3),
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: DesignSystem.spacing3),
            child: Container(
              width: double.infinity,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
      ),
    );
  }
}
