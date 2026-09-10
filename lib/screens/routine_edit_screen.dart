import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_filter_bar.dart';
import '../widgets/exercise_media.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';

class RoutineEditScreen extends StatefulWidget {
  const RoutineEditScreen({super.key});

  @override
  State<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends State<RoutineEditScreen> {
  late final String _id = fit.activeRoutineId!;
  late final TextEditingController _name =
      TextEditingController(text: fit.activeRoutine?.name ?? '');
  final TextEditingController _search = TextEditingController();
  String _q = '';
  bool _favsOnly = false;
  String? _placeId;
  String? _muscle;
  bool _noGearOnly = false;
  String? _equipment;
  String? _difficulty;

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _q = '';
      _favsOnly = false;
      _placeId = null;
      _muscle = null;
      _noGearOnly = false;
      _equipment = null;
      _difficulty = null;
    });
  }

  List<Exercise> get _filtered {
    return filterExerciseList(
      fit.allExercises,
      query: _q,
      favoritesOnly: _favsOnly,
      favorites: fit.favorites,
      placeId: _placeId,
      places: fit.places,
      muscleFilter: _muscle,
      noGearOnly: _noGearOnly,
      equipmentFilter: _equipment,
      difficultyFilter: _difficulty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final routine = fit.activeRoutine;
    if (routine == null) {
      return const SizedBox.shrink();
    }
    final list = _filtered;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              itemCount: (list.isEmpty ? 1 : list.length) + 1,
              itemBuilder: (context, i) {
                if (i == 0) return _header(gc, routine.exerciseIds.length);
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.magnifyingGlass, size: 36, color: gc.textTertiary),
                          const SizedBox(height: 10),
                          Text(t.noExercisesFound,
                              style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                          const SizedBox(height: 4),
                          Text(t.noExercisesHint,
                              textAlign: TextAlign.center,
                              style: AppTheme.s(12, color: gc.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }
                return _pickRow(gc, list[i - 1]);
              },
            ),
          ),
          if (routine.exerciseIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: t.startWorkout,
                icon: Ic.play,
                onTap: () => fit.startRoutine(routine),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(GymColors gc, int count) {
    final routine = fit.activeRoutine!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          RoundBtn(icon: Ic.chevronLeft, onTap: fit.closeRoutineEdit),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _name,
              autofocus: fit.activeRoutine?.name.isEmpty ?? false,
              style: AppTheme.d(22, weight: FontWeight.w700, color: gc.text, letterSpacing: 0.5),
              cursorColor: gc.accent,
              textCapitalization: TextCapitalization.words,
              onChanged: (v) => fit.renameRoutine(_id, v),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: t.routineName,
                hintStyle: AppTheme.d(22, weight: FontWeight.w700, color: gc.textTertiary),
              ),
            ),
          ),
          GestureDetector(
            onTap: _confirmDelete,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(PhosphorIconsRegular.trash, size: 20, color: gc.textTertiary),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Text(t.schedule, style: AppTheme.d(12, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 3)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (int i = 0; i < 7; i++) _dayToggle(gc, i)],
        ),
        const SizedBox(height: 24),
        Text(t.exercisesWithCount(count), style: AppTheme.d(12, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 3)),
        const SizedBox(height: 10),
        if (routine.exerciseIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(t.addFromList, style: AppTheme.s(13, color: gc.textTertiary)),
          )
        else ...[
          if (routine.exerciseIds.length > 1) ...[
            Text(t.dragToReorder, style: AppTheme.s(11, color: gc.textTertiary)),
            const SizedBox(height: 8),
          ],
          ReorderableListView(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            physics: const NeverScrollableScrollPhysics(),
            // ignore: deprecated_member_use
            onReorder: (from, to) => fit.reorderRoutineExercise(routine.id, from, to),
            children: [
              for (int i = 0; i < fit.routineExercises(routine).length; i++)
                _chosenRow(gc, fit.routineExercises(routine)[i], i),
            ],
          ),
        ],
        const SizedBox(height: 16),
        ExerciseFilterBar(
          searchController: _search,
          searchHint: t.addExercises,
          onSearchChanged: (v) => setState(() => _q = v),
          favoritesOnly: _favsOnly,
          onToggleFavorites: () => setState(() => _favsOnly = !_favsOnly),
          places: fit.places,
          selectedPlaceId: _placeId,
          onSelectPlace: (p) => setState(() => _placeId = p),
          onManagePlaces: () => fit.goPlaces(),
          selectedMuscle: _muscle,
          onSelectMuscle: (m) => setState(() => _muscle = m),
          noGearOnly: _noGearOnly,
          onToggleNoGear: () => setState(() {
            _noGearOnly = !_noGearOnly;
            if (_noGearOnly) _equipment = null;
          }),
          selectedEquipment: _equipment,
          onSelectEquipment: (e) => setState(() {
            _equipment = e;
            if (_equipment != null) _noGearOnly = false;
          }),
          selectedDifficulty: _difficulty,
          onSelectDifficulty: (d) => setState(() => _difficulty = d),
          favoriteCount: fit.favouriteCount,
          onClearAll: _clearFilters,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _dayToggle(GymColors gc, int i) {
    final weekday = i + 1;
    final on = fit.weeklyPlan[weekday] == _id;
    return GestureDetector(
      onTap: () => fit.assignRoutineToDay(weekday, on ? null : _id),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: on ? gc.ember : gc.bgRaised2,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(t.weekdayInitial(i + 1),
            style: AppTheme.d(14, weight: FontWeight.w700, color: on ? gc.onEmber : gc.textSecondary)),
      ),
    );
  }

  Widget _chosenRow(GymColors gc, Exercise ex, int index) {
    return Container(
      key: ValueKey(ex.id),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: gc.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        ReorderableDragStartListener(
          index: index,
          child: Semantics(
            label: t.reorderHandle(exerciseName(ex)),
            child: SizedBox(
              width: 34,
              height: 44,
              child: Icon(PhosphorIconsRegular.dotsSixVertical, size: 18, color: gc.textTertiary),
            ),
          ),
        ),
        SizedBox(width: 44, child: ExerciseMedia(ex: ex, height: 44, radius: 10)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(exerciseName(ex), style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
        ),
        Semantics(
          button: true,
          label: t.removeFromRoutine,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => fit.toggleRoutineExercise(_id, ex.id),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: gc.bgRaised2, shape: BoxShape.circle),
                  child: SvgPathIcon(Ic.close, size: 14, color: gc.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _pickRow(GymColors gc, Exercise ex) {
    final inRoutine = fit.routineHas(_id, ex.id);
    return GestureDetector(
      onTap: () => fit.toggleRoutineExercise(_id, ex.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          border: Border.all(color: inRoutine ? gc.ember : gc.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          SizedBox(width: 44, child: ExerciseMedia(ex: ex, height: 44, radius: 10)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exerciseName(ex), style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                const SizedBox(height: 2),
                Text('${muscleLabel(ex.primary)} · ${t.equipment(ex.equipment)}', style: AppTheme.s(12, color: gc.textSecondary)),
              ],
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: inRoutine ? gc.ember : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: inRoutine ? gc.ember : gc.border, width: 2),
            ),
            child: inRoutine
                ? SvgPathIcon(Ic.checkBold, size: 14, color: gc.onEmber)
                : Icon(PhosphorIconsRegular.plus, size: 15, color: gc.textSecondary),
          ),
        ]),
      ),
    );
  }

  void _confirmDelete() {
    final gc = context.gc;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: gc.bgRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.deleteRoutine, style: AppTheme.s(15, weight: FontWeight.w600, color: gc.text)),
              const SizedBox(height: 18),
              PrimaryButton(
                label: t.deleteCaps,
                bg: gc.accent,
                onTap: () {
                  Navigator.pop(context);
                  fit.deleteRoutine(_id);
                  fit.closeRoutineEdit();
                },
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  child: Text(t.cancelCaps,
                      style: AppTheme.d(14, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
