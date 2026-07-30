import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';

class EnhancedSearchSheet extends StatefulWidget {
  final Map<String, dynamic>? currentFilters;
  final ValueChanged<Map<String, dynamic>> onApply;
  final VoidCallback onClear;

  const EnhancedSearchSheet({
    super.key,
    this.currentFilters,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<EnhancedSearchSheet> createState() => _EnhancedSearchSheetState();

  static void show(
    BuildContext context, {
    Map<String, dynamic>? currentFilters,
    required ValueChanged<Map<String, dynamic>> onApply,
    required VoidCallback onClear,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EnhancedSearchSheet(
        currentFilters: currentFilters,
        onApply: onApply,
        onClear: onClear,
      ),
    );
  }
}

class _EnhancedSearchSheetState extends State<EnhancedSearchSheet> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String _sortBy = 'Recent';
  DateTimeRange? _dateRange;
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters ?? {});
    _searchController.text = _filters['search'] as String? ?? '';
    _selectedStatus = _filters['status'] as String?;
    _sortBy = _filters['sortBy'] as String? ?? 'Recent';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.bottomSheetRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(),
            if (_filters.isNotEmpty) _buildActiveFilters(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimens.lg),
                    _buildSearchInput(),
                    const SizedBox(height: AppDimens.xxl),
                    _buildStatusFilter(),
                    const SizedBox(height: AppDimens.xxl),
                    _buildDateRangeFilter(),
                    const SizedBox(height: AppDimens.xxl),
                    _buildSortByDropdown(),
                    const SizedBox(height: AppDimens.xxxl),
                    _buildActionButtons(),
                    const SizedBox(height: AppDimens.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: AppDimens.sm),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.xl,
        AppDimens.xl,
        AppDimens.xl,
        AppDimens.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: AppDimens.sm),
          const Expanded(
            child: Text(
              'Filters & Sort',
              style: TextStyle(
                fontSize: AppDimens.fontXl,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            color: AppColors.textTertiary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final entries = _filters.entries.where((e) => e.value != null && e.value != '' && e.value != 'Recent').toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
      child: Wrap(
        spacing: AppDimens.sm,
        runSpacing: AppDimens.sm,
        children: entries.map((entry) {
          final label = _filterLabel(entry.key, entry.value);
          return Chip(
            label: Text(
              label,
              style: const TextStyle(
                fontSize: AppDimens.fontXs,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            deleteIconColor: AppColors.primary,
            backgroundColor: AppColors.primarySurface,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            ),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onDeleted: () {
              setState(() {
                _filters.remove(entry.key);
                if (entry.key == 'status') _selectedStatus = null;
                if (entry.key == 'search') _searchController.clear();
                if (entry.key == 'sortBy') _sortBy = 'Recent';
              });
            },
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(String key, dynamic value) {
    switch (key) {
      case 'search':
        return '"$value"';
      case 'status':
        return 'Status: $value';
      case 'sortBy':
        return 'Sort: $value';
      case 'dateFrom':
        return 'From: ${value.toString().split(' ')[0]}';
      case 'dateTo':
        return 'To: ${value.toString().split(' ')[0]}';
      default:
        return '$key: $value';
    }
  }

  Widget _buildSearchInput() {
    return Container(
      height: AppDimens.inputHeight,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: AppDimens.fontBase,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: const TextStyle(
            color: AppColors.textHint,
            fontSize: AppDimens.fontMd,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    setState(() => _searchController.clear());
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.lg,
            vertical: 0,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = ['CONFIRMED', 'TENTATIVE', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontSize: AppDimens.fontSm,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        SizedBox(
          height: AppDimens.chipHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: statuses.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppDimens.sm),
            itemBuilder: (_, index) {
              final status = statuses[index];
              final isSelected = _selectedStatus == status;
              return FilterChip(
                label: Text(
                  _formatStatus(status),
                  style: TextStyle(
                    fontSize: AppDimens.fontSm,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.background,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? status : null;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'CONFIRMED':
        return 'Confirmed';
      case 'TENTATIVE':
        return 'Tentative';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: AppDimens.fontSm,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        Row(
          children: [
            Expanded(child: _buildDateField('From', true)),
            const SizedBox(width: AppDimens.md),
            Expanded(child: _buildDateField('To', false)),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(String label, bool isFrom) {
    final date = isFrom ? _dateRange?.start : _dateRange?.end;
    final displayText = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : label;

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            if (isFrom) {
              final end = _dateRange?.end ?? picked;
              _dateRange = DateTimeRange(start: picked, end: end);
            } else {
              final start = _dateRange?.start ?? picked;
              _dateRange = DateTimeRange(start: start, end: picked);
            }
          });
        }
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: date != null ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: AppDimens.xs),
            Text(
              displayText,
              style: TextStyle(
                fontSize: AppDimens.fontSm,
                fontWeight: FontWeight.w500,
                color: date != null ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortByDropdown() {
    final options = ['Recent', 'Amount', 'Name'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(
            fontSize: AppDimens.fontSm,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButton<String>(
            value: _sortBy,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textTertiary,
            ),
            dropdownColor: AppColors.surface,
            style: const TextStyle(
              fontSize: AppDimens.fontBase,
              color: AppColors.textPrimary,
            ),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _sortBy = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedStatus = null;
                _sortBy = 'Recent';
                _dateRange = null;
                _filters.clear();
              });
              widget.onClear();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(
                fontSize: AppDimens.fontMd,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          flex: 2,
          child: Container(
            height: AppDimens.buttonHeight,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                final filters = <String, dynamic>{};
                if (_searchController.text.isNotEmpty) {
                  filters['search'] = _searchController.text;
                }
                if (_selectedStatus != null) {
                  filters['status'] = _selectedStatus;
                }
                if (_sortBy != 'Recent') {
                  filters['sortBy'] = _sortBy;
                }
                if (_dateRange?.start != null) {
                  filters['dateFrom'] = _dateRange!.start.toIso8601String();
                }
                if (_dateRange?.end != null) {
                  filters['dateTo'] = _dateRange!.end.toIso8601String();
                }
                widget.onApply(filters);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: AppDimens.fontBase,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
