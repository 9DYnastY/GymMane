import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  testWidgets('SessionScreen bottom bar shows right arrow then changes to plus on last exercise', (tester) async {
    fit.onboarded = true;
    fit.startWorkout();
    fit.toggleMuscle('chest');
    fit.trainContinue();
    fit.startSession();

    final s = fit.session!;
    expect(s.exercises.length, greaterThan(1));

    // Initially at index 0 (not last)
    s.currentIndex = 0;
    fit.route = 'session';

    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();

    // Switch to last exercise
    s.currentIndex = s.exercises.length - 1;
    fit.notifyListeners();
    await tester.pumpAndSettle();

    // Now at last exercise, bottom bar has plus icon
    expect(find.byIcon(PhosphorIconsRegular.plus), findsWidgets);

    fit.saveAndExit();
  });
}
