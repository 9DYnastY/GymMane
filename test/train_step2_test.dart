import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/widgets/exercise_filter_bar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  testWidgets('TrainScreen step 2 displays ExerciseFilterBar and reset button', (tester) async {
    fit.onboarded = true;
    fit.selectedMuscles.clear();
    fit.selectedMuscles.addAll(['chest', 'triceps']);
    fit.trainContinue();
    fit.route = 'train';

    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();

    // Verify ExerciseFilterBar is present
    expect(find.byType(ExerciseFilterBar), findsOneWidget);

    // Verify Reset button icon is present
    expect(find.byIcon(PhosphorIconsRegular.arrowCounterClockwise), findsOneWidget);

    // Verify Plus button icon is present
    expect(find.byIcon(PhosphorIconsRegular.plus), findsOneWidget);

    // Verify picks initially non-empty
    expect(fit.sessionPicks.isNotEmpty, true);

    // Tap reset button -> clears picks
    await tester.tap(find.byIcon(PhosphorIconsRegular.arrowCounterClockwise));
    await tester.pumpAndSettle();
    expect(fit.sessionPicks.isEmpty, true);

    // Tap reset button again -> restores default picks
    await tester.tap(find.byIcon(PhosphorIconsRegular.arrowCounterClockwise));
    await tester.pumpAndSettle();
    expect(fit.sessionPicks.isNotEmpty, true);

    fit.route = 'home';
  });
}
