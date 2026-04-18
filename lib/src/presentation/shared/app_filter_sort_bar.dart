import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_text.dart';

/// A generic filter region (body area, category, etc.) for [AppFilterSortBar].
class FilterRegion {
  final String storageKey;
  final String filterLabel;

  const FilterRegion({required this.storageKey, required this.filterLabel});
}

/// Compact filter and sort bar widget with minimal UI footprint.
/// 
/// Features:
/// - Compact search field
/// - Filter button (filter icon) that opens filter options
/// - Minimal sort button (arrow icon) that opens a discreet dropdown
/// - Toggle ASC/DESC by clicking the same sort option again
class AppFilterSortBar extends StatelessWidget {
  /// Current filter text
  final String filterText;
  
  /// Callback when filter text changes
  final ValueChanged<String> onFilterChanged;
  
  /// Current sort option label (e.g., "Date", "Name")
  final String currentSortLabel;
  
  /// Whether current sort is ascending
  final bool isAscending;
  
  /// Available sort options
  final List<String> sortOptions;
  
  /// Callback when sort option is selected.
  /// First parameter is the option label, second is whether it should be ascending.
  /// If the same option is selected again, isAscending should be toggled.
  final void Function(String option, bool isAscending) onSortOptionSelected;
  
  /// Placeholder text for the search field
  final String searchPlaceholder;

  /// Current body-area filters ([FilterRegion.storageKey]; empty if none).
  final List<String> currentBodyAreaFilter;

  /// Coarse body-area choices shown as chips (fixed order).
  final List<FilterRegion> bodyAreaRegions;

  /// Current equipment filters (empty list if no filter)
  final List<String> currentEquipmentFilter;

  /// Available equipment options for filtering
  final List<String> equipmentOptions;
  
  /// Current favorite filter (true means favorites only)
  final bool currentFavoriteFilter;

  /// Callback when body-area filters change
  final ValueChanged<List<String>>? onBodyAreaFilterChanged;
  
  /// Callback when equipment filters change
  final ValueChanged<List<String>>? onEquipmentFilterChanged;
  
  /// Callback when favorite filter changes
  final ValueChanged<bool>? onFavoriteFilterChanged;

  /// Whether to show filter button (default: true)
  final bool showFilterButton;

  const AppFilterSortBar({
    super.key,
    required this.filterText,
    required this.onFilterChanged,
    required this.currentSortLabel,
    required this.isAscending,
    required this.sortOptions,
    required this.onSortOptionSelected,
    this.searchPlaceholder = 'Search',
    this.currentBodyAreaFilter = const [],
    this.bodyAreaRegions = const [],
    this.currentEquipmentFilter = const [],
    this.equipmentOptions = const [],
    this.currentFavoriteFilter = false,
    this.onBodyAreaFilterChanged,
    this.onEquipmentFilterChanged,
    this.onFavoriteFilterChanged,
    this.showFilterButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
      child: Row(
        children: [
          // Search field - takes most of the space
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: searchPlaceholder,
                  prefixIcon: Icon(Icons.search, color: colors.outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radii.md),
                    borderSide: BorderSide(color: colors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radii.md),
                    borderSide: BorderSide(color: colors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radii.md),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: spacing.md,
                    vertical: spacing.sm,
                  ),
                  filled: true,
                  fillColor: colors.surface,
                ),
                onChanged: onFilterChanged,
              ),
            ),
          ),
          
          SizedBox(width: spacing.sm),
          
          // Filter button (if enabled)
          if (showFilterButton &&
              (onBodyAreaFilterChanged != null ||
                  onEquipmentFilterChanged != null ||
                  onFavoriteFilterChanged != null))
            _FilterButton(
              currentBodyAreaFilter: currentBodyAreaFilter,
              bodyAreaRegions: bodyAreaRegions,
              currentEquipmentFilter: currentEquipmentFilter,
              equipmentOptions: equipmentOptions,
              currentFavoriteFilter: currentFavoriteFilter,
              onBodyAreaFilterChanged: onBodyAreaFilterChanged,
              onEquipmentFilterChanged: onEquipmentFilterChanged,
              onFavoriteFilterChanged: onFavoriteFilterChanged,
            ),
          
          if (showFilterButton &&
              (onBodyAreaFilterChanged != null ||
                  onEquipmentFilterChanged != null ||
                  onFavoriteFilterChanged != null))
          SizedBox(width: spacing.sm),
          
          // Compact sort button
          _SortButton(
            currentLabel: currentSortLabel,
            isAscending: isAscending,
            sortOptions: sortOptions,
            onSortOptionSelected: onSortOptionSelected,
          ),
        ],
      ),
    );
  }
}

/// Compact sort button that opens a dropdown menu.
class _SortButton extends StatelessWidget {
  final String currentLabel;
  final bool isAscending;
  final List<String> sortOptions;
  final void Function(String option, bool isAscending) onSortOptionSelected;

  const _SortButton({
    required this.currentLabel,
    required this.isAscending,
    required this.sortOptions,
    required this.onSortOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();

    return PopupMenuButton<String>(
      icon: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        padding: EdgeInsets.all(spacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outline),
          borderRadius: BorderRadius.circular(radii.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: colors.primary,
            ),
            SizedBox(width: spacing.xs),
            Icon(
              Icons.sort,
              size: 18,
              color: colors.outline,
            ),
          ],
        ),
      ),
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.md),
      ),
      itemBuilder: (context) => sortOptions.map((option) {
        final isSelected = option == currentLabel;
        return PopupMenuItem<String>(
          value: option,
          child: Row(
            children: [
              Expanded(
                child: AppText(
                  option,
                  style: AppTextStyle.body,
                ),
              ),
              if (isSelected)
                Icon(
                  isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: colors.primary,
                ),
            ],
          ),
        );
      }).toList(),
      onSelected: (option) {
        // Toggle ASC/DESC if same option selected, otherwise set new option as ASC
        if (option == currentLabel) {
          // Toggle direction
          onSortOptionSelected(option, !isAscending);
        } else {
          // New option, default to ascending
          onSortOptionSelected(option, true);
        }
      },
    );
  }
}

/// Compact filter button that opens a tile-based filter sheet.
class _FilterButton extends StatelessWidget {
  final List<String> currentBodyAreaFilter;
  final List<FilterRegion> bodyAreaRegions;
  final List<String> currentEquipmentFilter;
  final List<String> equipmentOptions;
  final bool currentFavoriteFilter;
  final ValueChanged<List<String>>? onBodyAreaFilterChanged;
  final ValueChanged<List<String>>? onEquipmentFilterChanged;
  final ValueChanged<bool>? onFavoriteFilterChanged;

  const _FilterButton({
    required this.currentBodyAreaFilter,
    required this.bodyAreaRegions,
    required this.currentEquipmentFilter,
    required this.equipmentOptions,
    required this.currentFavoriteFilter,
    required this.onBodyAreaFilterChanged,
    required this.onEquipmentFilterChanged,
    required this.onFavoriteFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();
    
    // Check if any filter is active
    final hasActiveFilter = currentFavoriteFilter ||
        currentBodyAreaFilter.isNotEmpty ||
        currentEquipmentFilter.isNotEmpty;
    final activeFilterCount = (currentFavoriteFilter ? 1 : 0) +
        currentBodyAreaFilter.length +
        currentEquipmentFilter.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radii.md),
        onTap: () => _openFilterSheet(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              padding: EdgeInsets.all(spacing.sm),
              decoration: BoxDecoration(
                color: hasActiveFilter
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.surface,
                border: Border.all(
                  color: hasActiveFilter ? colors.primary : colors.outline,
                  width: hasActiveFilter ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(radii.md),
              ),
              child: Icon(
                Icons.filter_list,
                size: 18,
                color: hasActiveFilter ? colors.primary : colors.outline,
              ),
            ),
            if (activeFilterCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(radii.full),
                  ),
                  child: Text(
                    activeFilterCount.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();

    var selectedBodyAreas = List<String>.from(currentBodyAreaFilter);
    var selectedEquipment = List<String>.from(currentEquipmentFilter);
    var favoritesOnly = currentFavoriteFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radii.lg)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final hasAnyFilter = favoritesOnly ||
                selectedBodyAreas.isNotEmpty ||
                selectedEquipment.isNotEmpty;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                spacing.lg,
                spacing.lg,
                spacing.lg,
                spacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          'Filters',
                          style: AppTextStyle.title,
                        ),
                      ),
                      if (hasAnyFilter)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              favoritesOnly = false;
                              selectedBodyAreas = [];
                              selectedEquipment = [];
                            });
                        onFavoriteFilterChanged?.call(false);
                        onBodyAreaFilterChanged?.call([]);
                        onEquipmentFilterChanged?.call([]);
                          },
                          child: AppText(
                            'Clear all',
                            style: AppTextStyle.body,
                            color: colors.primary,
                          ),
                        ),
                      if (hasAnyFilter)
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: AppText(
                            'Apply',
                            style: AppTextStyle.body,
                            color: colors.primary,
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          color: colors.outline,
                          tooltip: 'Close',
                        ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),
                  if (onFavoriteFilterChanged != null) ...[
                    _FilterTile(
                      label: 'Favourites',
                      isSelected: favoritesOnly,
                      leadingIcon:
                          favoritesOnly ? Icons.favorite : Icons.favorite_border,
                      selectedColor: colors.error,
                      onTap: () {
                        final newValue = !favoritesOnly;
                        setState(() {
                          favoritesOnly = newValue;
                        });
                        onFavoriteFilterChanged?.call(newValue);
                      },
                    ),
                    SizedBox(height: spacing.lg),
                  ],
                  if (onBodyAreaFilterChanged != null &&
                      bodyAreaRegions.isNotEmpty) ...[
                    AppText(
                      'Body area',
                      style: AppTextStyle.label,
                    ),
                    SizedBox(height: spacing.sm),
                    _BodyAreaFilterTileWrap(
                      regions: bodyAreaRegions,
                      selectedKeys: selectedBodyAreas,
                      onToggle: (storageKey, isSelected) {
                        setState(() {
                          if (isSelected) {
                            selectedBodyAreas.remove(storageKey);
                          } else {
                            selectedBodyAreas.add(storageKey);
                          }
                        });
                        onBodyAreaFilterChanged?.call(
                          List<String>.from(selectedBodyAreas),
                        );
                      },
                    ),
                    SizedBox(height: spacing.lg),
                  ],
                  if (onEquipmentFilterChanged != null) ...[
                    AppText(
                      'Equipment',
                      style: AppTextStyle.label,
                    ),
                    SizedBox(height: spacing.sm),
                    _FilterTileWrap(
                      options: equipmentOptions,
                      selectedValues: selectedEquipment,
                      onToggle: (value, isSelected) {
                        setState(() {
                          if (isSelected) {
                            selectedEquipment.remove(value);
                          } else {
                            selectedEquipment.add(value);
                          }
                        });
                        onEquipmentFilterChanged?.call(
                          List<String>.from(selectedEquipment),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BodyAreaFilterTileWrap extends StatelessWidget {
  final List<FilterRegion> regions;
  final List<String> selectedKeys;
  final void Function(String storageKey, bool isSelected) onToggle;

  const _BodyAreaFilterTileWrap({
    required this.regions,
    required this.selectedKeys,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();

    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: regions.map((region) {
        final key = region.storageKey;
        final isSelected = selectedKeys.contains(key);
        return _FilterTile(
          label: region.filterLabel,
          isSelected: isSelected,
          onTap: () => onToggle(key, isSelected),
        );
      }).toList(),
    );
  }
}

class _FilterTileWrap extends StatelessWidget {
  final List<String> options;
  final List<String> selectedValues;
  final void Function(String value, bool isSelected) onToggle;

  const _FilterTileWrap({
    required this.options,
    required this.selectedValues,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();

    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: options.map((option) {
        final isSelected = selectedValues.contains(option);
        return _FilterTile(
          label: option,
          isSelected: isSelected,
          onTap: () => onToggle(option, isSelected),
        );
      }).toList(),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? leadingIcon;
  final Color? selectedColor;
  final VoidCallback onTap;

  const _FilterTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leadingIcon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();
    final effectiveSelectedColor = selectedColor ?? colors.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final textColor = isSelected
        ? effectiveSelectedColor
        : onSurface.withValues(alpha: 0.85);
    final backgroundColor = isSelected
        ? effectiveSelectedColor.withValues(alpha: 0.12)
        : colors.surface;
    final borderColor = isSelected ? effectiveSelectedColor : colors.outline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radii.sm),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(radii.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 18,
                  color: textColor,
                ),
                SizedBox(width: spacing.xs),
              ],
              AppText(
                label,
                style: AppTextStyle.body,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
