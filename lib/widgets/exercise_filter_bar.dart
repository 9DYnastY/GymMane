import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../catalog/exercise_catalog.dart';
import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../models/place.dart';
import '../services/exercise_match.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'svg_icon.dart';
import 'ui_kit.dart';

/// Pure filtering function matching the logic across GymMane
List<Exercise> filterExerciseList(
  List<Exercise> exercises, {
  String query = '',
  bool favoritesOnly = false,
  Map<String, bool> favorites = const {},
  String? placeId,
  List<GymPlace> places = const [],
  String? muscleFilter,
  bool noGearOnly = false,
  String? equipmentFilter,
  String? difficultyFilter,
}) {
  final q = query.trim().toLowerCase();
  final matchFn = q.isNotEmpty ? exerciseSearch(q) : null;
  final GymPlace? activePlace = (placeId != null && placeId.isNotEmpty)
      ? places.where((p) => p.id == placeId).firstOrNull
      : null;
  final Set<String>? gearHere =
      activePlace == null ? null : {...activePlace.equipment, 'Bodyweight'};

  return exercises.where((ex) {
    if (favoritesOnly && favorites[ex.id] != true) return false;
    if (matchFn != null) {
      final zh = exerciseName(ex).toLowerCase();
      final mus = muscleLabel(ex.primary).toLowerCase();
      if (!matchFn(ex) && !zh.contains(q) && !mus.contains(q)) return false;
    }
    if (gearHere != null && !gearHere.contains(ex.equipment)) {
      return false;
    }
    if (muscleFilter != null &&
        ex.primary != muscleFilter &&
        !ex.secondary.contains(muscleFilter)) {
      return false;
    }
    if (noGearOnly && ex.equipment != 'Bodyweight') {
      return false;
    }
    if (equipmentFilter != null && ex.equipment != equipmentFilter) {
      return false;
    }
    if (difficultyFilter != null && ex.difficulty != difficultyFilter) {
      return false;
    }
    return true;
  }).toList();
}

class _FilterChipItem {
  const _FilterChipItem(this.label, this.active, this.onTap);
  final String label;
  final bool active;
  final VoidCallback onTap;
}

/// Reusable filter bar with Search input, Favorites toggle, Place chips,
/// Muscle group pills, Equipment pills, and Difficulty pills.
class ExerciseFilterBar extends StatelessWidget {
  const ExerciseFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.favoritesOnly,
    required this.onToggleFavorites,
    this.places = const [],
    this.selectedPlaceId,
    this.onSelectPlace,
    this.onManagePlaces,
    required this.selectedMuscle,
    required this.onSelectMuscle,
    this.noGearOnly = false,
    this.onToggleNoGear,
    this.selectedEquipment,
    this.onSelectEquipment,
    required this.selectedDifficulty,
    required this.onSelectDifficulty,
    this.searchHint,
    this.favoriteCount = 0,
    this.onClearAll,
    this.actions,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool favoritesOnly;
  final VoidCallback onToggleFavorites;

  final List<GymPlace> places;
  final String? selectedPlaceId;
  final ValueChanged<String?>? onSelectPlace;
  final VoidCallback? onManagePlaces;

  final String? selectedMuscle;
  final ValueChanged<String?> onSelectMuscle;

  final bool noGearOnly;
  final VoidCallback? onToggleNoGear;
  final String? selectedEquipment;
  final ValueChanged<String?>? onSelectEquipment;

  final String? selectedDifficulty;
  final ValueChanged<String?> onSelectDifficulty;

  final String? searchHint;
  final int favoriteCount;
  final VoidCallback? onClearAll;
  final List<Widget>? actions;

  bool get hasActiveFilter =>
      searchController.text.isNotEmpty ||
      favoritesOnly ||
      (selectedPlaceId != null && selectedPlaceId!.isNotEmpty) ||
      selectedMuscle != null ||
      noGearOnly ||
      selectedEquipment != null ||
      selectedDifficulty != null;

  Widget _sectionHeader(GymColors gc, String label, {bool showClear = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTheme.s(10, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.5)),
        if (showClear && hasActiveFilter && onClearAll != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClearAll,
            child: Text(t.clearFilters,
                style: AppTheme.s(11, weight: FontWeight.w600, color: gc.accent)),
          ),
      ],
    );
  }

  Widget _chipRow(
    List<_FilterChipItem> items,
    GymColors gc, {
    required double hPad,
    required double vPad,
    required double fontSize,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (int i = 0; i < items.length; i++) ...[
          Pill(
            label: items[i].label,
            bg: items[i].active ? gc.ember : gc.bgRaised2,
            fg: items[i].active ? gc.onEmber : gc.textSecondary,
            onTap: items[i].onTap,
            hPad: hPad,
            vPad: vPad,
            fontSize: fontSize,
          ),
          if (i < items.length - 1) const SizedBox(width: 8),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final showPlaces = onSelectPlace != null;
    final showEquipment = onSelectEquipment != null || onToggleNoGear != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search bar and optional actions
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: gc.bgRaised,
                  border: Border.all(color: gc.border),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(children: [
                  SvgPathIcon(Ic.search, size: 16, color: gc.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: AppTheme.s(14, color: gc.text),
                      cursorColor: gc.accent,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: searchHint ?? t.searchExercises,
                        hintStyle: AppTheme.s(14, color: gc.textSecondary),
                      ),
                    ),
                  ),
                  if (searchController.text.isNotEmpty)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(PhosphorIconsRegular.xCircle, size: 18, color: gc.textTertiary),
                      ),
                    ),
                ]),
              ),
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              for (final action in actions!) ...[
                const SizedBox(width: 10),
                action,
              ],
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Favorites toggle
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggleFavorites,
          child: Semantics(
            button: true,
            selected: favoritesOnly,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: favoritesOnly ? gc.accentSoft : Colors.transparent,
                border: Border.all(color: favoritesOnly ? gc.accent : gc.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Stack(children: [
                      if (favoritesOnly)
                        SvgPathIcon(const [
                          IconPath(
                              'M12 2l3.09 6.26L22 9.27l-5 4.87L18.18 21 12 17.77 5.82 21 7 14.14l-5-4.87 6.91-1.01z',
                              fill: true)
                        ], size: 18, color: gc.accent),
                      SvgPathIcon(Ic.star, size: 18, color: favoritesOnly ? gc.accent : gc.textTertiary),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    favoriteCount > 0
                        ? '${t.favouritesOnly.toUpperCase()} · $favoriteCount'
                        : t.favouritesOnly.toUpperCase(),
                    style: AppTheme.d(12,
                        weight: FontWeight.w600,
                        color: favoritesOnly ? gc.accent : gc.text,
                        letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Place filter chips (if enabled)
        if (showPlaces) ...[
          _sectionHeader(gc, t.placeFilterLabel, showClear: true),
          const SizedBox(height: 8),
          _chipRow([
            _FilterChipItem(
              t.placeAll,
              selectedPlaceId == null || selectedPlaceId!.isEmpty,
              () => onSelectPlace?.call(null),
            ),
            for (final place in places)
              _FilterChipItem(
                place.name,
                selectedPlaceId == place.id,
                () => onSelectPlace?.call(selectedPlaceId == place.id ? null : place.id),
              ),
            if (onManagePlaces != null)
              _FilterChipItem(
                places.isEmpty ? t.placeNew : '+',
                false,
                onManagePlaces!,
              ),
          ], gc, hPad: 14, vPad: 8, fontSize: 13),
          const SizedBox(height: 12),
        ],

        // Muscle filter chips
        _sectionHeader(gc, t.muscleFilter, showClear: !showPlaces),
        const SizedBox(height: 8),
        _chipRow([
          for (final id in kFilterMuscles)
            _FilterChipItem(
              muscleLabel(id),
              selectedMuscle == id,
              () => onSelectMuscle(selectedMuscle == id ? null : id),
            ),
        ], gc, hPad: 14, vPad: 8, fontSize: 13),
        const SizedBox(height: 12),

        // Equipment filter chips (if enabled)
        if (showEquipment) ...[
          _sectionHeader(gc, t.equipmentLabel),
          const SizedBox(height: 8),
          _chipRow([
            if (onToggleNoGear != null)
              _FilterChipItem(
                t.noGearOnly,
                noGearOnly,
                onToggleNoGear!,
              ),
            for (final e in kFilterEquipment)
              _FilterChipItem(
                t.equipment(e),
                selectedEquipment == e,
                () => onSelectEquipment?.call(selectedEquipment == e ? null : e),
              ),
          ], gc, hPad: 12, vPad: 6, fontSize: 12),
          const SizedBox(height: 12),
        ],

        // Level filter chips
        _sectionHeader(gc, t.levelFilter),
        const SizedBox(height: 8),
        _chipRow([
          for (final d in kDifficulties)
            _FilterChipItem(
              t.difficulty(d),
              selectedDifficulty == d,
              () => onSelectDifficulty(selectedDifficulty == d ? null : d),
            ),
        ], gc, hPad: 12, vPad: 6, fontSize: 12),
        const SizedBox(height: 8),
      ],
    );
  }
}
