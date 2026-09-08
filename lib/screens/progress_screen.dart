import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../models/progress_shot.dart';
import '../models/workout.dart';
import '../services/media_store.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/body_map.dart';
import '../widgets/charts.dart';
import '../widgets/dialogs.dart';
import '../widgets/exercise_filter_bar.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';
import 'share_sheet.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final change = fit.volumeChangePct;
    final split = fit.muscleSplit;
    final prs = fit.personalRecords;
    final bw = fit.bodyweightSeries;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: ScreenTitle(t.progress)),
                Semantics(
                  button: true,
                  label: t.share,
                  child: GestureDetector(
                    onTap: () => showShareSheet(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: gc.bgRaised,
                        shape: BoxShape.circle,
                        border: Border.all(color: gc.border),
                      ),
                      child: Icon(PhosphorIconsRegular.shareNetwork, size: 17, color: gc.text),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SoftCard(
              radius: 24,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.totalVolume30d,
                      style: AppTheme.d(12, weight: FontWeight.w600, color: gc.brass, letterSpacing: 3)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: fit.volumeValue(fit.volume30dKg),
                          style: AppTheme.d(44, weight: FontWeight.w700, color: gc.text),
                          children: [
                            TextSpan(text: ' ${fit.volumeUnit}', style: AppTheme.d(20, weight: FontWeight.w700, color: gc.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (change != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: change >= 0 ? gc.sageSoft : gc.accentSoft,
                                borderRadius: BorderRadius.circular(8)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              SvgPathIcon(Ic.trendUp, size: 12, color: change >= 0 ? gc.sage : gc.accent),
                              const SizedBox(width: 4),
                              Text(t.vsLastMonth(change),
                                  style: AppTheme.s(11, weight: FontWeight.w600, color: change >= 0 ? gc.sage : gc.accent)),
                            ]),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(t.volumeCumulative,
                      style: AppTheme.s(12, color: gc.textSecondary, height: 1.4)),
                  const SizedBox(height: 18),
                  VolumeChart(
                    points: fit.volumeChartPoints,
                    label: fit.volumeValue,
                    unit: fit.volumeUnit,
                    xLabels: ['-30 d', '-15 d', t.noteToday.toLowerCase()],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SoftCard(
              radius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.consistency,
                          style: AppTheme.d(14, weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
                      Text(t.sessionsLogged(fit.totalSessions),
                          style: AppTheme.s(12, color: gc.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Heatmap(levels: fit.heatmapLevels, onTapDay: (i) => _showDay(context, i)),
                  const SizedBox(height: 14),
                  Row(children: [
                    SvgPathIcon(Ic.flame, size: 14, color: gc.accent),
                    const SizedBox(width: 6),
                    Text(t.streakDays(fit.currentStreak),
                        style: AppTheme.s(13, weight: FontWeight.w600, color: gc.text)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _weekRhythm(gc),
            const SizedBox(height: 22),
            const _WorkoutHistoryCard(),
            const SizedBox(height: 22),
            SoftCard(
              radius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.bodyweight,
                              style: AppTheme.d(14, weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          if (fit.latestBodyweight != null)
                            RichText(
                              text: TextSpan(
                                text: fit.weightValue(fit.latestBodyweight!.kg),
                                style: AppTheme.d(26, weight: FontWeight.w700, color: gc.text),
                                children: [
                                  TextSpan(
                                      text: ' ${fit.units}',
                                      style: AppTheme.d(14, weight: FontWeight.w700, color: gc.textSecondary)),
                                ],
                              ),
                            )
                          else
                            Text(t.notLoggedYet, style: AppTheme.s(13, color: gc.textSecondary)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _logBodyweight(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(color: gc.emberSoft, borderRadius: BorderRadius.circular(100)),
                          child: Text(t.logShort,
                              style: AppTheme.d(13, weight: FontWeight.w600, color: gc.ember, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                  if (bw.length >= 2) ...[
                    const SizedBox(height: 14),
                    Sparkline(values: bw),
                  ],
                  if (fit.bodyweight.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final e in fit.bodyweightHistory.take(5)) _bwRow(context, gc, e),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            _timelineCard(gc),
            const SizedBox(height: 22),
            _measuresCard(gc),
            const SizedBox(height: 22),
            _StrengthCard(),
            const SizedBox(height: 22),
            const _MuscleMapCard(),
            const SizedBox(height: 22),
            SoftCard(
              radius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.muscleSplit,
                      style: AppTheme.d(14, weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
                  const SizedBox(height: 14),
                  if (split.isEmpty)
                    Text(t.splitEmpty,
                        style: AppTheme.s(13, color: gc.textSecondary))
                  else
                    SplitBars(entries: split),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SoftCard(
              radius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.personalRecords,
                      style: AppTheme.d(14, weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
                  const SizedBox(height: 14),
                  if (prs.isEmpty)
                    Text(t.prEmpty,
                        style: AppTheme.s(13, color: gc.textSecondary))
                  else
                    for (int i = 0; i < prs.length; i++) _prRow(gc, prs[i], i < prs.length - 1),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _allTime(gc),
          ],
        ),
      ),
    );
  }

  Widget _weekRhythm(GymColors gc) {
    final by = fit.sessionsByWeekday;
    final best = fit.busiestWeekday;
    final top = by.values.fold(0, (m, v) => v > m ? v : m);
    final today = DateTime.now().weekday;
    final bar = gc.accent;

    return SoftCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.weekRhythm,
                  style: AppTheme.d(14, weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
              Text(best == 0 ? t.weekRhythmHint : t.weekRhythmBest(t.weekday(best).toLowerCase()),
                  style: AppTheme.s(12, color: gc.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: () {
                      final w = (t.firstWeekday + i - 1) % 7 + 1;
                      final n = by[w] ?? 0;
                      final h = top == 0 ? 0.0 : 62 * n / top;
                      final on = n == top && n > 0;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(n == 0 ? '' : '$n',
                              style: AppTheme.d(11,
                                  weight: FontWeight.w700,
                                  color: on ? gc.accent : gc.textTertiary)),
                          const SizedBox(height: 4),
                          Container(
                            height: h < 4 ? 4 : h,
                            decoration: BoxDecoration(
                              color: n == 0
                                  ? gc.heatEmpty
                                  : bar.withValues(alpha: on ? 1 : 0.3 + 0.4 * n / top),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(t.weekdayInitial(w).toUpperCase(),
                              style: AppTheme.d(11,
                                  weight: FontWeight.w600,
                                  color: w == today ? gc.text : gc.textTertiary)),
                        ],
                      );
                    }(),
                  ),
                ],
              ],
            ),
          ),
          if (fit.sessions.isEmpty) ...[
            const SizedBox(height: 12),
            Text(t.weekRhythmEmpty, style: AppTheme.s(13, color: gc.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _allTime(GymColors gc) {
    final time = fit.totalTime;
    final hours = time.inHours;
    final avg = fit.averageSession;

    Widget cell(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  maxLines: 1,
                  style: AppTheme.s(9.5,
                      weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 1)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    maxLines: 1,
                    style: AppTheme.d(20, weight: FontWeight.w700, color: gc.text)),
              ),
            ],
          ),
        );

    return SoftCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.allTime,
              style: AppTheme.d(14, weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
          const SizedBox(height: 16),
          Row(children: [
            cell(t.allTimeSessions, '${fit.totalSessions}'),
            cell(t.allTimeTime, hours >= 1 ? t.hoursShort(hours) : '${time.inMinutes} min'),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            cell(t.allTimeVolume, fit.volumeLabel(fit.totalVolumeKg)),
            cell(t.allTimeSets, '${fit.totalSets}'),
          ]),
          if (fit.sessions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(t.allTimeAvg('${avg.inMinutes} min'),
                style: AppTheme.s(12.5, color: gc.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _timelineCard(GymColors gc) {
    final pair = fit.comparePair;
    final last = fit.lastEntry;
    final left = fit.daysUntilPhoto;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: fit.goTimeline,
      child: SoftCard(
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.timeline,
                      style: AppTheme.d(14,
                          weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
                ),
                if (last != null && left != null)
                  Text(fit.photoDue ? t.photoDueNow : t.photoNextIn(left),
                      style: AppTheme.s(11.5,
                          weight: FontWeight.w600,
                          color: fit.photoDue ? gc.accent : gc.textTertiary)),
                const SizedBox(width: 8),
                Icon(PhosphorIconsRegular.caretRight, size: 15, color: gc.textTertiary),
              ],
            ),
            const SizedBox(height: 14),
            if (last == null)
              Text(t.timelineHint, style: AppTheme.s(13, color: gc.textSecondary, height: 1.5))
            else
              Row(
                children: [
                  if (pair != null) ...[
                    Expanded(child: _shotThumb(gc, pair.from)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(PhosphorIconsBold.arrowRight, size: 14, color: gc.accent),
                    ),
                    Expanded(child: _shotThumb(gc, pair.to)),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.daysApart(fit.compareDays),
                              style: AppTheme.d(15, weight: FontWeight.w700, color: gc.text)),
                          const SizedBox(height: 2),
                          Text(t.photoCount(fit.shotCount),
                              style: AppTheme.s(12, color: gc.textSecondary)),
                        ],
                      ),
                    ),
                  ] else ...[
                    Expanded(child: _shotThumb(gc, last)),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: Text(t.compareNeedTwo,
                          style: AppTheme.s(12.5, color: gc.textSecondary, height: 1.45)),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _shotThumb(GymColors gc, ProgressEntry entry) {
    final name = entry.media.isEmpty ? null : entry.media.first;
    final path = name == null ? null : MediaStore.pathFor(name);
    return AspectRatio(
      aspectRatio: 0.78,
      child: Container(
        decoration: BoxDecoration(
          color: gc.bgRaised2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gc.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: path == null
            ? Icon(PhosphorIconsRegular.imageSquare, size: 16, color: gc.textTertiary)
            : Image.file(File(path), fit: BoxFit.cover, gaplessPlayback: true,
                errorBuilder: (_, _, _) =>
                    Icon(PhosphorIconsRegular.imageSquare, size: 16, color: gc.textTertiary)),
      ),
    );
  }

  Widget _measuresCard(GymColors gc) {
    final tracked = fit.trackedMeasures;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: fit.goMeasures,
      child: SoftCard(
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.measures,
                      style: AppTheme.d(14,
                          weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
                ),
                Icon(PhosphorIconsRegular.caretRight, size: 15, color: gc.textTertiary),
              ],
            ),
            const SizedBox(height: 12),
            if (tracked.isEmpty)
              Text(t.measuresHint, style: AppTheme.s(13, color: gc.textSecondary, height: 1.5))
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final key in tracked.take(6)) _measureChip(gc, key),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _measureChip(GymColors gc, String key) {
    final latest = fit.latestMeasure(key)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.measureName(key),
              style: AppTheme.s(10.5, weight: FontWeight.w600, color: gc.textTertiary)),
          const SizedBox(height: 3),
          Text(fit.measureLabel(key, latest.value),
              style: AppTheme.d(15, weight: FontWeight.w700, color: gc.text)),
        ],
      ),
    );
  }

  Widget _prRow(GymColors gc, ({String id, String name, double topWeight, double oneRm}) pr, bool border) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: border ? Border(bottom: BorderSide(color: gc.border)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(t.catalogName(pr.id, pr.name),
                  style: AppTheme.s(14, weight: FontWeight.w500, color: gc.text))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fit.weightLabel(pr.topWeight), style: AppTheme.d(18, weight: FontWeight.w700, color: gc.text)),
              Text(t.oneRmEst(fit.weightLabel(pr.oneRm)), style: AppTheme.s(11, color: gc.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bwRow(BuildContext context, GymColors gc, BodyweightEntry e) {
    return Row(
      children: [
        Expanded(child: Text(t.shortDateYear(e.date), style: AppTheme.s(12, color: gc.textSecondary))),
        Text(fit.weightLabel(e.kg), style: AppTheme.s(13, weight: FontWeight.w600, color: gc.text)),
        Semantics(
          button: true,
          label: '${t.delete} ${fit.weightLabel(e.kg)}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => fit.deleteBodyweight(e),
            child: SizedBox(
              width: 44,
              height: 40,
              child: Icon(PhosphorIconsRegular.trash, size: 14, color: gc.textTertiary),
            ),
          ),
        ),
      ],
    );
  }

  void _showDay(BuildContext context, int index) {
    final date = fit.heatmapDate(index);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DaySheet(date: date),
    );
  }

  void _logBodyweight(BuildContext context) {
    final start = fit.latestBodyweight?.kg ?? fit.profile.weightKg;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LogBodyweightSheet(start: start),
    );
  }
}

class _MuscleMapCard extends StatefulWidget {
  const _MuscleMapCard();

  @override
  State<_MuscleMapCard> createState() => _MuscleMapCardState();
}

class _MuscleMapCardState extends State<_MuscleMapCard> {
  int _days = 7;
  String? _focus;

  void _setDays(int d) => setState(() {
        _days = d;
        _focus = null;
      });

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final sets = fit.muscleSetsOver(_days);
    final heat = fit.muscleHeatOver(_days);
    final focus = _focus;
    final behind = fit.neglectedMuscles(_days);

    return SoftCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.muscleMap,
                  style: AppTheme.d(14, weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
              SegToggle(
                [
                  SegOption(t.days7, _days == 7, () => _setDays(7)),
                  SegOption(t.days30, _days == 30, () => _setDays(30)),
                ],
                hPad: 11,
                vPad: 5,
                fontSize: 11,
              ),
            ],
          ),
          const SizedBox(height: 16),
          BodyHeatMap(
            intensity: heat,
            focus: focus,
            onTap: (id) => setState(() => _focus = focus == id ? null : id),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Text(t.heatLow, style: AppTheme.s(11, color: gc.textTertiary)),
            const SizedBox(width: 8),
            for (int i = 0; i <= heatLevels; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: heatLevelColor(gc, i),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Text(t.heatHigh, style: AppTheme.s(11, color: gc.textTertiary)),
          ]),
          const SizedBox(height: 14),
          Container(
            constraints: const BoxConstraints(minHeight: 36),
            alignment: Alignment.centerLeft,
            child: focus != null
                ? _readout(gc, focus, sets[focus] ?? 0, heat[focus] ?? 0)
                : Text(
                    sets.isEmpty
                        ? t.muscleMapEmpty
                        : behind.isEmpty
                            ? t.muscleMapHint
                            : t.muscleMapBehind(behind.map(t.muscle).join(' · ')),
                    style: AppTheme.s(13, color: gc.textSecondary),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _readout(GymColors gc, String id, double sets, double heat) {
    return Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: heatColor(gc, heat), shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text(t.muscle(id), style: AppTheme.s(13, weight: FontWeight.w600, color: gc.text)),
      const SizedBox(width: 8),
      Expanded(
        child: Text('${t.setCount(sets.round())} · ${t.ofTarget((heat * 100).round())}',
            style: AppTheme.s(13, color: gc.textSecondary)),
      ),
    ]);
  }
}

class _StrengthCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final tracked = fit.trackedExercises;
    final id = fit.activeStrengthId;

    return SoftCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.strength1rm,
              style: AppTheme.d(14, weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
          const SizedBox(height: 14),
          if (id == null)
            Text(t.strengthEmpty,
                style: AppTheme.s(13, color: gc.textSecondary))
          else
            ..._chart(gc, id, tracked),
        ],
      ),
    );
  }

  List<Widget> _chart(
    GymColors gc,
    String id,
    List<({String id, String name, int sessions})> tracked,
  ) {
    final series = fit.oneRmSeries(id);
    final first = series.first, last = series.last;
    final delta = last - first;
    final up = delta >= 0;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          RichText(
            text: TextSpan(
              text: fit.weightValue(last),
              style: AppTheme.d(32, weight: FontWeight.w700, color: gc.text),
              children: [
                TextSpan(
                    text: ' ${fit.units}',
                    style: AppTheme.d(15, weight: FontWeight.w700, color: gc.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (delta.abs() >= 0.1)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: up ? gc.sageSoft : gc.accentSoft, borderRadius: BorderRadius.circular(8)),
                child: Text('${up ? '+' : ''}${fit.weightLabel(delta)}',
                    style: AppTheme.s(11, weight: FontWeight.w600, color: up ? gc.sage : gc.accent)),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Sparkline(values: series, height: 56, color: up ? gc.sage : gc.accent),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final e in tracked.take(8)) ...[
            Pill(
              label: t.catalogName(e.id, e.name),
              bg: e.id == id ? gc.ember : gc.bgRaised2,
              fg: e.id == id ? gc.onEmber : gc.textSecondary,
              onTap: () => fit.setStrengthExercise(e.id),
              hPad: 12,
              vPad: 7,
              fontSize: 12,
            ),
            const SizedBox(width: 8),
          ],
        ]),
      ),
    ];
  }
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: fit, builder: (context, _) => _body(context));
  }

  Widget _body(BuildContext context) {
    final gc = context.gc;
    final s = fit.daySummary(date);
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: gc.border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 18),
            Text(t.longDate(date),
                style: AppTheme.d(20, weight: FontWeight.w700, color: gc.text)),
            const SizedBox(height: 14),
            if (s == null) ...[
              Text(t.restDay, style: AppTheme.s(14, color: gc.textSecondary)),
              const SizedBox(height: 18),
              PrimaryButton(
                label: t.logWorkoutOnDate,
                icon: Ic.plus,
                onTap: () {
                  Navigator.of(context).pop();
                  _openSessionEditor(context, null, defaultDate: date);
                },
              ),
            ] else ...[
              Row(children: [
                Expanded(child: _stat(gc, t.exercisesCaps, '${s.exercises}')),
                const SizedBox(width: 10),
                Expanded(child: _stat(gc, t.setsCaps, '${s.sets}')),
                const SizedBox(width: 10),
                Expanded(child: _stat(gc, t.volume, fit.volumeLabel(s.volume))),
                if (s.durationSec > 0) ...[
                  const SizedBox(width: 10),
                  Expanded(child: _stat(gc, t.timeCaps, '${s.durationSec ~/ 60}m')),
                ],
              ]),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.tapToEdit, style: AppTheme.s(11, color: gc.textTertiary)),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _openSessionEditor(context, null, defaultDate: date);
                    },
                    child: Text('+ ${t.logPastWorkout}',
                        style: AppTheme.s(12, weight: FontWeight.w600, color: gc.ember)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final logged in fit.sessionsOn(date)) ...[
                _sessionHeader(context, gc, logged),
                for (final ex in [...logged.exercises]) _loggedRow(context, gc, logged, ex),
                const SizedBox(height: 6),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _sessionHeader(BuildContext context, GymColors gc, LoggedSession s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${t.setCount(s.setCount)} · ${fit.volumeLabel(s.volume)}',
              style: AppTheme.s(11, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 1),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              _openSessionEditor(context, s);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.pencilSimple, size: 14, color: gc.textSecondary),
                  const SizedBox(width: 4),
                  Text(t.editWorkout, style: AppTheme.s(11, color: gc.textSecondary)),
                ],
              ),
            ),
          ),
          if (!fit.isSessionActive) ...[
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _confirmResume(context, s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: gc.emberSoft,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(PhosphorIconsFill.play, size: 11, color: gc.ember),
                  const SizedBox(width: 6),
                  Text(t.continueWorkout,
                      style: AppTheme.d(11, weight: FontWeight.w700, color: gc.ember, letterSpacing: 1)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmResume(BuildContext context, LoggedSession s) async {
    final ok = await askConfirm(
      context,
      title: t.continueWorkout,
      body: t.continueWorkoutBody,
      confirmLabel: t.continueWorkout,
    );
    if (!ok || !context.mounted) return;
    Navigator.of(context).pop();
    fit.resumeLoggedSession(s);
  }

  Widget _loggedRow(BuildContext context, GymColors gc, LoggedSession s, LoggedExercise e) {
    final detail = e.sets.map((x) => '${fit.weightValue(x.weight)}×${x.reps}').join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: gc.accent, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).pop();
                _openSessionEditor(context, s);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.catalogName(e.id, e.name), style: AppTheme.s(13, weight: FontWeight.w600, color: gc.text)),
                  const SizedBox(height: 2),
                  Text(detail, style: AppTheme.s(11, color: gc.textSecondary)),
                ],
              ),
            ),
          ),
          Semantics(
            button: true,
            label: '${t.editEntry} ${t.catalogName(e.id, e.name)}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showEditLoggedSheet(context, s, e),
              child: SizedBox(
                width: 40,
                height: 44,
                child: Icon(PhosphorIconsRegular.pencilSimple, size: 16, color: gc.textTertiary),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: '${t.deleteCaps} ${t.catalogName(e.id, e.name)}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _confirmDelete(context, s, e),
              child: SizedBox(
                width: 40,
                height: 44,
                child: Icon(PhosphorIconsRegular.trash, size: 16, color: gc.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, LoggedSession s, LoggedExercise e) async {
    final ok = await askConfirm(
      context,
      title: t.deleteEntry,
      body: t.deleteEntryBody(t.catalogName(e.id, e.name)),
      confirmLabel: t.delete,
    );
    if (ok) fit.deleteLoggedExercise(s, e);
  }

  Widget _stat(GymColors gc, String label, String value) {
    Widget fit1(Widget child) =>
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child);
    return SoftCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fit1(Text(label,
              maxLines: 1,
              softWrap: false,
              style: AppTheme.s(9, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 1))),
          const SizedBox(height: 4),
          fit1(Text(value,
              maxLines: 1, softWrap: false, style: AppTheme.d(17, weight: FontWeight.w700, color: gc.text))),
        ],
      ),
    );
  }
}

class _LogBodyweightSheet extends StatefulWidget {
  const _LogBodyweightSheet({required this.start});
  final double start;
  @override
  State<_LogBodyweightSheet> createState() => _LogBodyweightSheetState();
}

class _LogBodyweightSheetState extends State<_LogBodyweightSheet> {
  late double _shown = ((fit.toDisplayWeight(widget.start)) * 10).round() / 10;

  void _bump(double d) => setState(() => _shown = ((_shown + d) * 10).round() / 10);

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: gc.border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 18),
          Text(t.logBodyweight,
              style: AppTheme.d(14, weight: FontWeight.w600, color: gc.text, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(t.trackWeight, style: AppTheme.s(13, color: gc.textSecondary)),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _round(gc, '–', () => _bump(-0.1)),
              const SizedBox(width: 22),
              SizedBox(
                width: 130,
                child: Text('${fmt(_shown)} ${fit.units}',
                    textAlign: TextAlign.center,
                    style: AppTheme.d(40, weight: FontWeight.w700, color: gc.text)),
              ),
              const SizedBox(width: 22),
              _round(gc, '+', () => _bump(0.1)),
            ],
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: t.save,
            onTap: () {
              fit.addBodyweight(fit.fromDisplayWeight(_shown));
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _round(GymColors gc, String glyph, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: gc.bgRaised2, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(glyph, style: TextStyle(color: gc.text, fontSize: 26, height: 1)),
      ),
    );
  }
}

void _openSessionEditor(BuildContext context, LoggedSession? session, {DateTime? defaultDate}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SessionEditorSheet(session: session, defaultDate: defaultDate),
  );
}

Future<void> _confirmDeleteSession(BuildContext context, LoggedSession s) async {
  final gc = context.gc;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
      backgroundColor: gc.bgRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(t.deleteEntry, style: AppTheme.d(18, weight: FontWeight.w700, color: gc.text)),
      content: Text(t.deleteSessionConfirm, style: AppTheme.s(13, color: gc.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dctx).pop(false),
          child: Text(t.cancel, style: AppTheme.s(14, color: gc.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dctx).pop(true),
          child: Text(t.delete, style: AppTheme.s(14, weight: FontWeight.w700, color: gc.accent)),
        ),
      ],
    ),
  );
  if (ok == true) fit.deleteSession(s);
}

Future<void> _editNumberDialog(
  BuildContext context, {
  required String title,
  required double current,
  required bool decimal,
  required void Function(double) apply,
}) async {
  final gc = context.gc;
  final initial = decimal
      ? (current == current.roundToDouble() ? '${current.toInt()}' : '$current')
      : '${current.round()}';
  final controller = TextEditingController(text: initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: initial.length);

  final raw = await showDialog<String>(
    context: context,
    builder: (dctx) => AlertDialog(
      backgroundColor: gc.bgRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: AppTheme.d(14, weight: FontWeight.w700, color: gc.text, letterSpacing: 2)),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        textAlign: TextAlign.center,
        style: AppTheme.d(32, weight: FontWeight.w700, color: gc.text),
        cursorColor: gc.accent,
        onSubmitted: (v) => Navigator.of(dctx).pop(v),
        decoration: InputDecoration(
          filled: true,
          fillColor: gc.bgRaised2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dctx).pop(),
          child: Text(t.cancel, style: AppTheme.s(14, color: gc.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dctx).pop(controller.text),
          child: Text(t.set, style: AppTheme.s(14, weight: FontWeight.w700, color: gc.accent)),
        ),
      ],
    ),
  );
  if (raw != null) {
    final v = double.tryParse(raw.replaceAll(',', '.'));
    if (v != null && v >= 0) apply(v);
  }
}

class _WorkoutHistoryCard extends StatefulWidget {
  const _WorkoutHistoryCard();

  @override
  State<_WorkoutHistoryCard> createState() => _WorkoutHistoryCardState();
}

class _WorkoutHistoryCardState extends State<_WorkoutHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final all = fit.allLoggedSessionsDesc;
    final visible = _expanded ? all : all.take(5).toList();

    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.workoutHistory,
                  style: AppTheme.d(14, weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
              GestureDetector(
                onTap: () => _openSessionEditor(context, null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: gc.emberSoft, borderRadius: BorderRadius.circular(100)),
                  child: Text(t.logShort,
                      style: AppTheme.d(13, weight: FontWeight.w600, color: gc.ember, letterSpacing: 1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (all.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(t.noWorkoutsYet, style: AppTheme.s(13, color: gc.textSecondary)),
            )
          else ...[
            for (final session in visible)
              _sessionItem(context, gc, session),
            if (all.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded
                            ? (appLanguage == 'zh' ? '收起' : 'Show less')
                            : (appLanguage == 'zh' ? '查看更多 (${all.length})' : 'Show all (${all.length})'),
                        style: AppTheme.s(13, weight: FontWeight.w600, color: gc.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown,
                        size: 14,
                        color: gc.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sessionItem(BuildContext context, GymColors gc, LoggedSession s) {
    final names = s.exercises.map((e) => t.catalogName(e.id, e.name)).join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(t.longDate(s.date),
                    style: AppTheme.s(14, weight: FontWeight.w700, color: gc.text)),
              ),
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: t.editWorkout,
                    child: GestureDetector(
                      onTap: () => _openSessionEditor(context, s),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(PhosphorIconsRegular.pencilSimple, size: 16, color: gc.ember),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: t.repeatWorkout,
                    child: GestureDetector(
                      onTap: () => fit.startFromLoggedSession(s),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(PhosphorIconsRegular.play, size: 16, color: gc.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: t.delete,
                    child: GestureDetector(
                      onTap: () => _confirmDeleteSession(context, s),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(PhosphorIconsRegular.trash, size: 16, color: gc.textTertiary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${s.exercises.length} ${appLanguage == 'zh' ? '个动作' : 'exercises'} · ${s.setCount} ${appLanguage == 'zh' ? '组' : 'sets'} · ${fit.volumeLabel(s.volume)}${s.durationSec > 0 ? ' · ${s.durationSec ~/ 60}m' : ''}',
            style: AppTheme.s(12, weight: FontWeight.w600, color: gc.ember),
          ),
          if (names.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(names,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.s(12, color: gc.textSecondary)),
          ],
        ],
      ),
    );
  }
}


class _SessionEditorSheet extends StatefulWidget {
  const _SessionEditorSheet({this.session, this.defaultDate});
  final LoggedSession? session;
  final DateTime? defaultDate;

  @override
  State<_SessionEditorSheet> createState() => _SessionEditorSheetState();
}

class _SessionEditorSheetState extends State<_SessionEditorSheet> {
  late LoggedSession _session;
  bool _isNew = false;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _session = widget.session!;
    } else {
      final targetDate = widget.defaultDate ?? DateTime.now();
      final existing = fit.sessionsOn(targetDate);
      if (existing.isNotEmpty) {
        _session = existing.first;
        _isNew = false;
      } else {
        _isNew = true;
        _session = fit.createPastSession(targetDate);
      }
    }
  }

  @override
  void dispose() {
    if (_isNew && _session.exercises.isEmpty) {
      fit.deleteSession(_session);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: gc.border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(t.editWorkout,
                        style: AppTheme.d(18, weight: FontWeight.w700, color: gc.text)),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _session.date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setState(() {
                          _session = fit.updateSessionDate(
                            _session,
                            DateTime(picked.year, picked.month, picked.day, _session.date.hour, _session.date.minute),
                          );
                          _isNew = false;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: gc.bgRaised2,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: gc.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.calendar, size: 14, color: gc.ember),
                          const SizedBox(width: 6),
                          Text(t.shortDateYear(_session.date),
                              style: AppTheme.s(12, weight: FontWeight.w600, color: gc.text)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(child: _editorStat(gc, t.exercisesCaps, '${_session.exercises.length}')),
                  const SizedBox(width: 10),
                  Expanded(child: _editorStat(gc, t.setsCaps, '${_session.setCount}')),
                  const SizedBox(width: 10),
                  Expanded(child: _editorStat(gc, t.volume, fit.volumeLabel(_session.volume))),
                  if (_session.durationSec > 0) ...[
                    const SizedBox(width: 10),
                    Expanded(child: _editorStat(gc, t.timeCaps, '${_session.durationSec ~/ 60}m')),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  if (_session.exercises.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Text(
                          appLanguage == 'zh' ? '点击下方按钮添加动作' : 'Tap below to add exercises',
                          style: AppTheme.s(14, color: gc.textSecondary),
                        ),
                      ),
                    )
                  else
                    for (int exIdx = 0; exIdx < _session.exercises.length; exIdx++)
                      _exerciseCard(gc, _session.exercises[exIdx]),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: t.addExerciseToSession,
                    icon: Ic.plus,
                    onTap: () {
                      showExercisePickerSheet(
                        context,
                        onPick: (ex) {
                          setState(() {
                            fit.addLoggedExercise(_session, ex);
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_session.exercises.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        fit.startFromLoggedSession(_session);
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: gc.bgRaised2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: gc.border),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIconsRegular.play, size: 16, color: gc.accent),
                            const SizedBox(width: 8),
                            Text(t.repeatWorkout,
                                style: AppTheme.d(13, weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  GestureDetector(
                    onTap: () async {
                      final nav = Navigator.of(context);
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (dctx) => AlertDialog(
                          backgroundColor: gc.bgRaised,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text(t.deleteEntry, style: AppTheme.d(18, weight: FontWeight.w700, color: gc.text)),
                          content: Text(t.deleteSessionConfirm, style: AppTheme.s(13, color: gc.textSecondary)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dctx).pop(false),
                              child: Text(t.cancel, style: AppTheme.s(14, color: gc.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(dctx).pop(true),
                              child: Text(t.delete, style: AppTheme.s(14, weight: FontWeight.w700, color: gc.accent)),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && mounted) {
                        nav.pop();
                        fit.deleteSession(_session);
                      }
                    },
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      child: Text(t.delete,
                          style: AppTheme.s(13, color: gc.accent)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editorStat(GymColors gc, String label, String value) {
    Widget fit1(Widget child) =>
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child);
    return SoftCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fit1(Text(label,
              maxLines: 1,
              softWrap: false,
              style: AppTheme.s(9, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 1))),
          const SizedBox(height: 4),
          fit1(Text(value,
              maxLines: 1, softWrap: false, style: AppTheme.d(17, weight: FontWeight.w700, color: gc.text))),
        ],
      ),
    );
  }

  Widget _exerciseCard(GymColors gc, LoggedExercise e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.catalogName(e.id, e.name),
                  style: AppTheme.s(14, weight: FontWeight.w700, color: gc.text),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    fit.deleteLoggedExercise(_session, e);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(PhosphorIconsRegular.trash, size: 16, color: gc.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int setIdx = 0; setIdx < e.sets.length; setIdx++)
            _setRow(gc, e, setIdx, e.sets[setIdx]),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                fit.addLoggedSet(e);
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIconsRegular.plus, size: 14, color: gc.ember),
                  const SizedBox(width: 4),
                  Text(t.addSet, style: AppTheme.s(12, weight: FontWeight.w600, color: gc.ember)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setRow(GymColors gc, LoggedExercise e, int setIdx, LoggedSet st) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#${setIdx + 1}',
                style: AppTheme.s(12, weight: FontWeight.w600, color: gc.textTertiary)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _editNumberDialog(
                context,
                title: '${t.catalogName(e.id, e.name)} - ${t.weightLifted}',
                current: fit.toDisplayWeight(st.weight),
                decimal: true,
                apply: (v) {
                  setState(() {
                    fit.updateLoggedSet(_session, e, setIdx, weight: fit.fromDisplayWeight(v));
                  });
                },
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: gc.bgRaised,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: gc.border),
                ),
                alignment: Alignment.center,
                child: Text('${fit.weightValue(st.weight)} ${fit.units}',
                    style: AppTheme.s(13, weight: FontWeight.w600, color: gc.text)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('×', style: TextStyle(color: gc.textTertiary, fontSize: 13)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _editNumberDialog(
                context,
                title: '${t.catalogName(e.id, e.name)} - ${t.repsPerformed}',
                current: st.reps.toDouble(),
                decimal: false,
                apply: (v) {
                  setState(() {
                    fit.updateLoggedSet(_session, e, setIdx, reps: v.round());
                  });
                },
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: gc.bgRaised,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: gc.border),
                ),
                alignment: Alignment.center,
                child: Text('${st.reps} reps',
                    style: AppTheme.s(13, weight: FontWeight.w600, color: gc.text)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                fit.removeLoggedSet(_session, e, setIdx);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(PhosphorIconsRegular.x, size: 14, color: gc.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

void showEditLoggedSheet(BuildContext context, LoggedSession s, LoggedExercise e) {
  final gc = context.gc;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => AnimatedBuilder(
      animation: fit,
      builder: (sheetCtx, _) {
        if (!s.exercises.contains(e)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
          });
        }
        final repsOnly = fit.isRepsOnly(e.id);
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            border: Border.all(color: gc.border),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetHandle(),
                  const SizedBox(height: 18),
                  Text(t.catalogName(e.id, e.name), style: AppTheme.d(20, weight: FontWeight.w700, color: gc.text)),
                  const SizedBox(height: 4),
                  Text(t.editEntryHint, style: AppTheme.s(12, color: gc.textSecondary)),
                  const SizedBox(height: 16),
                  for (int i = 0; i < e.sets.length; i++) ...[
                    _editSetRow(gc, s, e, i, repsOnly),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => fit.addLoggedSet(e),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: gc.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(t.addSet,
                          style: AppTheme.s(13,
                              weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: t.done, onTap: () => Navigator.pop(sheetCtx), height: 52),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _editSetRow(GymColors gc, LoggedSession s, LoggedExercise e, int i, bool repsOnly) {
  final set = e.sets[i];
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(14)),
    child: Row(
      children: [
        SizedBox(
          width: 22,
          child: Text('${i + 1}', style: AppTheme.d(15, weight: FontWeight.w700, color: gc.text)),
        ),
        Expanded(
          child: Column(
            children: [
              Text(t.repsCol,
                  style: AppTheme.s(9.5, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 1)),
              const SizedBox(height: 2),
              StepperControl(
                value: '${set.reps}',
                onDec: () => fit.bumpLoggedReps(e, i, -1),
                onInc: () => fit.bumpLoggedReps(e, i, 1),
                minWidth: 30,
                btnSize: 26,
                gap: 8,
                fontSize: 14,
              ),
            ],
          ),
        ),
        if (!repsOnly)
          Expanded(
            child: Column(
              children: [
                Text(t.weightCol(fit.units.toUpperCase()),
                    style:
                        AppTheme.s(9.5, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 1)),
                const SizedBox(height: 2),
                StepperControl(
                  value: fit.weightValue(set.weight),
                  onDec: () => fit.bumpLoggedWeight(e, i, -1),
                  onInc: () => fit.bumpLoggedWeight(e, i, 1),
                  minWidth: 34,
                  btnSize: 26,
                  gap: 8,
                  fontSize: 14,
                ),
              ],
            ),
          ),
        Semantics(
          button: true,
          label: t.removeSet,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => fit.removeLoggedSet(s, e, i),
            child: SizedBox(
              width: 36,
              height: 40,
              child: Icon(PhosphorIconsRegular.x, size: 14, color: gc.textTertiary),
            ),
          ),
        ),
      ],
    ),
  );
}
