import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/body_map.dart';
import '../widgets/exercise_filter_bar.dart';
import '../widgets/exercise_media.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';
import 'exercises_screen.dart' show showCreateExerciseSheet;

class TrainScreen extends StatefulWidget {
  const TrainScreen({super.key});

  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _q = '';
  bool _favsOnly = false;
  String? _muscle;
  String? _difficulty;

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _q = '';
      _favsOnly = false;
      _muscle = null;
      _difficulty = null;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final review = fit.trainStep == 'review';
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RoundBtn(icon: Ic.closeThin, onTap: fit.closeTrain),
                Text(t.train, style: AppTheme.d(16, weight: FontWeight.w700, color: gc.text, letterSpacing: 2)),
                const SizedBox(width: 36),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: review ? _review(context, gc) : _select(context, gc),
            ),
          ),
          if (review) _startBar(context, gc),
        ],
      ),
    );
  }

  Widget _startBar(BuildContext context, GymColors gc) {
    final n = fit.sessionPicks.length;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border(top: BorderSide(color: gc.border)),
      ),
      child: PrimaryButton(
        label: n == 0 ? t.pickAnExercise : t.startCount(n),
        bg: n == 0 ? gc.bgRaised2 : gc.ember,
        fg: n == 0 ? gc.textTertiary : gc.onEmber,
        onTap: fit.startSession,
      ),
    );
  }

  Widget _select(BuildContext context, GymColors gc) {
    final hasSel = fit.selectedMuscles.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.step1, style: AppTheme.d(11, weight: FontWeight.w600, color: gc.brass, letterSpacing: 3)),
        const SizedBox(height: 4),
        Text(t.chooseFocus, style: AppTheme.d(26, weight: FontWeight.w700, color: gc.text, letterSpacing: 1)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            border: Border.all(color: gc.border),
            borderRadius: BorderRadius.circular(24),
          ),
          child: BodyMap(
            selected: fit.selectedMuscles.toSet(),
            onToggle: fit.toggleMuscle,
          ),
        ),
        const SizedBox(height: 6),
        Text(t.tapMuscles,
            textAlign: TextAlign.center, style: AppTheme.s(12, color: gc.textTertiary)),
        const SizedBox(height: 14),
        Container(
          constraints: const BoxConstraints(minHeight: 38),
          alignment: Alignment.centerLeft,
          child: hasSel
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final id in fit.selectedMuscles) _chip(gc, id)],
                )
              : Text(t.noMusclesYet,
                  style: AppTheme.s(13, color: gc.textTertiary)),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: t.continueBtn,
          bg: hasSel ? gc.ember : gc.bgRaised2,
          fg: hasSel ? gc.onEmber : gc.textTertiary,
          onTap: fit.trainContinue,
        ),
      ],
    );
  }

  Widget _chip(GymColors gc, String id) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: gc.emberSoft, borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(t.muscle(id), style: AppTheme.s(13, weight: FontWeight.w600, color: gc.ember)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => fit.toggleMuscle(id),
          child: SvgPathIcon(Ic.closeThin, size: 12, color: gc.ember),
        ),
      ]),
    );
  }

  Widget _review(BuildContext context, GymColors gc) {
    final hasFilters = _q.trim().isNotEmpty || _favsOnly || _muscle != null || _difficulty != null;
    final baseExercises = (_muscle != null || _q.trim().isNotEmpty) ? fit.allExercises : fit.reviewExercises();
    final exercises = filterExerciseList(
      baseExercises,
      query: _q,
      favoritesOnly: _favsOnly,
      favorites: fit.favorites,
      muscleFilter: _muscle,
      difficultyFilter: _difficulty,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                _clearFilters();
                fit.trainBack();
              },
              child: SvgPathIcon(Ic.chevronLeft, size: 20, color: gc.textSecondary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.step2, style: AppTheme.d(11, weight: FontWeight.w600, color: gc.brass, letterSpacing: 3)),
                Text(t.buildSession, style: AppTheme.d(20, weight: FontWeight.w700, color: gc.text)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        ExerciseFilterBar(
          searchController: _searchCtrl,
          searchHint: t.searchAllExercises,
          onSearchChanged: (v) => setState(() => _q = v),
          favoritesOnly: _favsOnly,
          onToggleFavorites: () => setState(() => _favsOnly = !_favsOnly),
          selectedMuscle: _muscle,
          onSelectMuscle: (m) => setState(() => _muscle = m),
          selectedDifficulty: _difficulty,
          onSelectDifficulty: (d) => setState(() => _difficulty = d),
          favoriteCount: fit.favouriteCount,
          onClearAll: _clearFilters,
          actions: [
            _resetPicksBtn(gc),
            _createExerciseBtn(context, gc),
          ],
        ),
        const SizedBox(height: 14),
        if (!hasFilters && exercises.isNotEmpty) ...[
          Text(t.pickedHint(exercises.length),
              style: AppTheme.s(12, color: gc.textTertiary)),
          const SizedBox(height: 12),
        ] else if (hasFilters && exercises.isNotEmpty) ...[
          Text(t.libraryCount(exercises.length),
              style: AppTheme.s(12, color: gc.textTertiary)),
          const SizedBox(height: 12),
        ],
        if (exercises.isEmpty)
          _emptyReview(context, gc, hasFilters)
        else
          for (final ex in exercises) ...[
            _pickRow(gc, ex),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _resetPicksBtn(GymColors gc) {
    final hasPicks = fit.sessionPicks.isNotEmpty;
    final tip = hasPicks ? '清空已选动作' : '恢复默认推荐';
    return Semantics(
      button: true,
      label: tip,
      child: Tooltip(
        message: tip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => fit.toggleResetPicks()),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasPicks ? gc.emberSoft : gc.bgRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: hasPicks ? gc.ember.withValues(alpha: 0.3) : gc.border),
            ),
            child: Icon(
              PhosphorIconsRegular.arrowCounterClockwise,
              size: 20,
              color: hasPicks ? gc.ember : gc.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _createExerciseBtn(BuildContext context, GymColors gc) {
    return GestureDetector(
      onTap: () => showCreateExerciseSheet(context, onCreated: (id) {
        fit.togglePick(id);
        _clearFilters();
      }),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: gc.emberSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gc.border),
        ),
        child: Icon(PhosphorIconsRegular.plus, size: 20, color: gc.ember),
      ),
    );
  }

  Widget _emptyReview(BuildContext context, GymColors gc, bool hasFilters) {
    if (hasFilters) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
        child: Column(
          children: [
            Text(t.noExercisesMatch,
                style: AppTheme.s(15, weight: FontWeight.w600, color: gc.text)),
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showCreateExerciseSheet(context, onCreated: (id) {
                fit.togglePick(id);
                _clearFilters();
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(t.createItInstead,
                    style: AppTheme.s(13, weight: FontWeight.w600, color: gc.accent)),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
      child: Column(
        children: [
          Text(t.nothingForFocus,
              style: AppTheme.s(15, weight: FontWeight.w600, color: gc.text)),
          const SizedBox(height: 4),
          Text(t.goBackPick,
              textAlign: TextAlign.center, style: AppTheme.s(13, color: gc.textSecondary)),
        ],
      ),
    );
  }

  Widget _pickRow(GymColors gc, Exercise ex) {
    final picked = fit.isPicked(ex.id);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => fit.togglePick(ex.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          border: Border.all(color: picked ? gc.ember : gc.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          SizedBox(width: 44, child: ExerciseMedia(ex: ex, height: 44, radius: 12)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exerciseName(ex), style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                const SizedBox(height: 2),
                Text(fit.lastSummaryFor(ex.id) ?? muscleLabel(ex.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.s(12, color: gc.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: picked ? gc.ember : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: picked ? gc.ember : gc.border, width: 2),
            ),
            child: picked ? Center(child: SvgPathIcon(Ic.checkBold, size: 13, color: gc.onEmber)) : null,
          ),
        ]),
      ),
    );
  }
}
