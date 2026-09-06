import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

enum EventFlowSkeletonVariant { list, grid, detail, chart }

class EventFlowSkeleton extends StatelessWidget {
  final EventFlowSkeletonVariant variant;
  final int itemCount;
  final double? width;
  final double? height;

  const EventFlowSkeleton({
    super.key,
    this.variant = EventFlowSkeletonVariant.list,
    this.itemCount = 3,
    this.width,
    this.height,
  });

  const EventFlowSkeleton.list({
    super.key,
    this.itemCount = 3,
    this.width,
    this.height,
  }) : variant = EventFlowSkeletonVariant.list;

  const EventFlowSkeleton.grid({
    super.key,
    this.itemCount = 6,
    this.width,
    this.height,
  }) : variant = EventFlowSkeletonVariant.grid;

  const EventFlowSkeleton.detail({
    super.key,
    this.width,
    this.height,
  })  : variant = EventFlowSkeletonVariant.detail,
       itemCount = 1;

  const EventFlowSkeleton.chart({
    super.key,
    this.width,
    this.height,
  })  : variant = EventFlowSkeletonVariant.chart,
       itemCount = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerLowest,
      child: switch (variant) {
        EventFlowSkeletonVariant.list => _buildListSkeleton(),
        EventFlowSkeletonVariant.grid => _buildGridSkeleton(),
        EventFlowSkeletonVariant.detail => _buildDetailSkeleton(),
        EventFlowSkeletonVariant.chart => _buildChartSkeleton(),
      },
    );
  }

  Widget _buildListSkeleton() {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: DesignSystem.spacing3),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                ),
              ),
              const SizedBox(width: DesignSystem.spacing3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
                      ),
                    ),
                    const SizedBox(height: DesignSystem.spacing1),
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: DesignSystem.spacing3,
        crossAxisSpacing: DesignSystem.spacing3,
        childAspectRatio: 1.2,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
        ),
      ),
    );
  }

  Widget _buildDetailSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
          ),
        ),
        const SizedBox(height: DesignSystem.spacing4),
        Container(
          height: 24,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
          ),
        ),
        const SizedBox(height: DesignSystem.spacing3),
        Container(
          height: 14,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
          ),
        ),
        const SizedBox(height: DesignSystem.spacing1),
        Container(
          height: 14,
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
          ),
        ),
        const SizedBox(height: DesignSystem.spacing1),
        Container(
          height: 14,
          width: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusXs),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSkeleton() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
      ),
    );
  }
}
