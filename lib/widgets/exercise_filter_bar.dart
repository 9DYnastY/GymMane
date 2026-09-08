import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../catalog/exercise_catalog.dart';
import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'exercise_media.dart';
import 'svg_icon.dart';
import 'ui_kit.dart';

/// Pure filtering function matching the logic across GymMane
List<Exercise> filterExerciseList(
  List<Exercise> exercises, {
  String query = '',
  bool favoritesOnly = false,
  Map<String, bool> favorites = const {},
  String? muscleFilter,
  String? difficultyFilter,
}) {
  final q = query.trim().toLowerCase();
  return exercises.where((ex) {
    if (favoritesOnly && favorites[ex.id] != true) return false;
    if (q.isNotEmpty) {
      final zh = exerciseName(ex).toLowerCase();
      final en = ex.name.toLowerCase();
      final mus = muscleLabel(ex.primary).toLowerCase();
      if (!zh.contains(q) && !en.contains(q) && !mus.contains(q)) return false;
    }
    if (muscleFilter != null &&
        ex.primary != muscleFilter &&
        !ex.secondary.contains(muscleFilter)) {
      return false;
    }
    if (difficultyFilter != null && ex.difficulty != difficultyFilter) {
      return false;
    }
    return true;
  }).toList();
}

/// Reusable filter bar with Search input, Favorites toggle, Muscle group pills, and Difficulty pills
class ExerciseFilterBar extends StatelessWidget {
  const ExerciseFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.favoritesOnly,
    required this.onToggleFavorites,
    required this.selectedMuscle,
    required this.onSelectMuscle,
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
  final String? selectedMuscle;
  final ValueChanged<String?> onSelectMuscle;
  final String? selectedDifficulty;
  final ValueChanged<String?> onSelectDifficulty;
  final String? searchHint;
  final int favoriteCount;
  final VoidCallback? onClearAll;
  final List<Widget>? actions;

  bool get hasActiveFilter =>
      searchController.text.isNotEmpty ||
      favoritesOnly ||
      selectedMuscle != null ||
      selectedDifficulty != null;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
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

        // Muscle filter chips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t.muscleFilter,
                style: AppTheme.s(10, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.5)),
            if (hasActiveFilter && onClearAll != null)
              GestureDetector(
                onTap: onClearAll,
                child: Text(t.clearFilters,
                    style: AppTheme.s(11, weight: FontWeight.w600, color: gc.accent)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (int i = 0; i < kFilterMuscles.length; i++) ...[
              Pill(
                label: muscleLabel(kFilterMuscles[i]),
                bg: selectedMuscle == kFilterMuscles[i] ? gc.ember : gc.bgRaised2,
                fg: selectedMuscle == kFilterMuscles[i] ? gc.onEmber : gc.textSecondary,
                onTap: () =>
                    onSelectMuscle(selectedMuscle == kFilterMuscles[i] ? null : kFilterMuscles[i]),
                hPad: 12,
                vPad: 6,
                fontSize: 12,
              ),
              if (i < kFilterMuscles.length - 1) const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(height: 12),

        // Level filter chips
        Text(t.levelFilter,
            style: AppTheme.s(10, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (int i = 0; i < kDifficulties.length; i++) ...[
              Pill(
                label: t.difficulty(kDifficulties[i]),
                bg: selectedDifficulty == kDifficulties[i] ? gc.ember : gc.bgRaised2,
                fg: selectedDifficulty == kDifficulties[i] ? gc.onEmber : gc.textSecondary,
                onTap: () => onSelectDifficulty(
                    selectedDifficulty == kDifficulties[i] ? null : kDifficulties[i]),
                hPad: 12,
                vPad: 6,
                fontSize: 12,
              ),
              if (i < kDifficulties.length - 1) const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Bottom sheet modal for selecting an exercise with full filtering capabilities
void showExercisePickerSheet(BuildContext context, {required void Function(Exercise) onPick}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ExercisePickerSheet(onPick: onPick),
  );
}

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet({required this.onPick});
  final void Function(Exercise) onPick;

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _favsOnly = false;
  String? _muscle;
  String? _difficulty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _searchController.clear();
      _query = '';
      _favsOnly = false;
      _muscle = null;
      _difficulty = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final all = fit.allExercises;
    final list = filterExerciseList(
      all,
      query: _query,
      favoritesOnly: _favsOnly,
      favorites: fit.favorites,
      muscleFilter: _muscle,
      difficultyFilter: _difficulty,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: gc.border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: ExerciseFilterBar(
              searchController: _searchController,
              onSearchChanged: (v) => setState(() => _query = v),
              favoritesOnly: _favsOnly,
              onToggleFavorites: () => setState(() => _favsOnly = !_favsOnly),
              selectedMuscle: _muscle,
              onSelectMuscle: (m) => setState(() => _muscle = m),
              selectedDifficulty: _difficulty,
              onSelectDifficulty: (d) => setState(() => _difficulty = d),
              favoriteCount: fit.favouriteCount,
              onClearAll: _clearAll,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.magnifyingGlass, size: 36, color: gc.textTertiary),
                          const SizedBox(height: 12),
                          Text(t.noExercisesFound,
                              style: AppTheme.s(15, weight: FontWeight.w600, color: gc.text)),
                          const SizedBox(height: 6),
                          Text(t.noExercisesHint,
                              textAlign: TextAlign.center,
                              style: AppTheme.s(13, color: gc.textSecondary)),
                          const SizedBox(height: 16),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _clearAll,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: gc.bgRaised2,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(t.clearFilters,
                                  style: AppTheme.s(13, weight: FontWeight.w600, color: gc.accent)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final ex = list[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: gc.bgRaised2,
                          border: Border.all(color: gc.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: SizedBox(
                            width: 44,
                            height: 44,
                            child: ExerciseMedia(ex: ex, height: 44, radius: 10),
                          ),
                          title: Text(exerciseName(ex),
                              style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                          subtitle: Text(
                            '${muscleLabel(ex.primary)} · ${t.equipment(ex.equipment)} · ${t.difficulty(ex.difficulty)}',
                            style: AppTheme.s(12, color: gc.textSecondary),
                          ),
                          trailing: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: gc.emberSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(PhosphorIconsRegular.plus, size: 16, color: gc.ember),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onPick(ex);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
