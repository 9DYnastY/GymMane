import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/models/live_session.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    fit.saveAndExit();
    fit.sessions.clear();
    fit.routines.clear();
    fit.onboarded = true;
  });

  test('finishing multiple live sessions on the same day consolidates them into a single record', () {
    final now = DateTime.now();

    // Session 1: Bench press 3 sets
    final s1 = WorkoutSession();
    s1.exercises = [
      SessionExercise('bench-press', 'Bench Press', 'chest', [
        SessionSet(10, 60, true),
        SessionSet(10, 60, true),
        SessionSet(8, 65, true),
      ]),
    ];
    fit.session = s1;
    fit.debugElapsedSeconds = 1800;
    fit.finishSession();

    expect(fit.sessions.length, 1);
    expect(fit.sessions.first.exercises.length, 1);
    expect(fit.sessions.first.exercises.first.sets.length, 3);
    expect(fit.sessions.first.durationSec, 1800);

    // Session 2 on the same day: Bench press 2 more sets + Incline press 3 sets
    final s2 = WorkoutSession();
    s2.exercises = [
      SessionExercise('bench-press', 'Bench Press', 'chest', [
        SessionSet(6, 70, true),
        SessionSet(5, 70, true),
      ]),
      SessionExercise('incline-bench-press', 'Incline Bench Press', 'chest', [
        SessionSet(12, 40, true),
        SessionSet(10, 45, true),
        SessionSet(10, 45, true),
      ]),
    ];
    fit.session = s2;
    fit.debugElapsedSeconds = 1200;
    fit.finishSession();

    // Must still have exactly ONE session for today!
    expect(fit.sessions.length, 1);
    final consolidated = fit.sessions.first;
    expect(consolidated.durationSec, 3000); // 1800 + 1200

    // Bench press should have 3 + 2 = 5 sets
    final bench = consolidated.exercises.firstWhere((e) => e.id == 'bench-press');
    expect(bench.sets.length, 5);
    expect(bench.sets[0].weight, 60);
    expect(bench.sets[1].weight, 60);
    expect(bench.sets[2].weight, 65);
    expect(bench.sets[3].weight, 70);
    expect(bench.sets[4].weight, 70);

    // Incline press should be appended as second exercise with 3 sets
    final incline = consolidated.exercises.firstWhere((e) => e.id == 'incline-bench-press');
    expect(incline.sets.length, 3);

    // allLoggedSessionsDesc should only contain 1 item
    expect(fit.allLoggedSessionsDesc.length, 1);
    expect(fit.sessionsOn(now).length, 1);
  });

  test('createPastSession returns existing session on same day rather than duplicating', () {
    final pastDate = DateTime(2026, 8, 15, 10, 0);

    final s1 = fit.createPastSession(pastDate, durationSec: 2000);
    fit.addLoggedSet(s1, LoggedExercise('squat', 'Squat', 'quads', []), reps: 10, weight: 100);

    expect(fit.sessions.length, 1);

    // Calling createPastSession again for the same calendar date
    final s2 = fit.createPastSession(DateTime(2026, 8, 15, 18, 30), durationSec: 1500);

    // Should return the exact same existing session instance
    expect(identical(s1, s2), true);
    expect(fit.sessions.length, 1);
  });

  test('updateSessionDate merges into target session if target date already has one', () {
    final day1 = DateTime(2026, 8, 1, 10, 0);
    final day2 = DateTime(2026, 8, 2, 10, 0);

    final s1 = fit.createPastSession(day1, durationSec: 1000);
    final ex1 = LoggedExercise('pullup', 'Pull-up', 'back', []);
    s1.exercises.add(ex1);
    fit.addLoggedSet(s1, ex1, reps: 8, weight: 0);

    final s2 = fit.createPastSession(day2, durationSec: 1500);
    final ex2 = LoggedExercise('deadlift', 'Deadlift', 'back', []);
    s2.exercises.add(ex2);
    fit.addLoggedSet(s2, ex2, reps: 5, weight: 120);

    expect(fit.sessions.length, 2);

    // Move day2's session to day1
    final result = fit.updateSessionDate(s2, DateTime(2026, 8, 1, 15, 0));

    // Sessions should now be consolidated into 1 session on day1
    expect(fit.sessions.length, 1);
    expect(identical(result, fit.sessions.first), true);
    expect(result.durationSec, 2500); // 1000 + 1500
    expect(result.exercises.any((e) => e.id == 'pullup'), true);
    expect(result.exercises.any((e) => e.id == 'deadlift'), true);
  });

  test('consolidateDailySessions consolidates duplicate same-day sessions on load', () {
    final day = DateTime(2026, 7, 10);
    // Artificially inject multiple sessions on the same day into fit.sessions
    fit.sessions.add(LoggedSession(
      day.add(const Duration(hours: 9)),
      1200,
      [LoggedExercise('bench-press', 'Bench Press', 'chest', [LoggedSet(10, 50)])],
    ));
    fit.sessions.add(LoggedSession(
      day.add(const Duration(hours: 15)),
      1800,
      [LoggedExercise('bench-press', 'Bench Press', 'chest', [LoggedSet(8, 60)])],
    ));

    expect(fit.sessions.length, 2);

    fit.consolidateDailySessions();

    expect(fit.sessions.length, 1);
    expect(fit.sessions.first.durationSec, 3000);
    expect(fit.sessions.first.exercises.single.sets.length, 2);
  });
}
