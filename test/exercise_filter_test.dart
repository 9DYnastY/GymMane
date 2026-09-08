import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/widgets/exercise_filter_bar.dart';

void main() {
  test('filterExerciseList filters by query (name or muscle)', () {
    final list = filterExerciseList(kExercises, query: 'bench press');
    expect(list.isNotEmpty, true);
    for (final e in list) {
      expect(e.name.toLowerCase().contains('bench') || e.primary.toLowerCase().contains('bench'), true);
    }
  });

  test('filterExerciseList filters by favorites only', () {
    final favId = kExercises.first.id;
    final list = filterExerciseList(
      kExercises,
      favoritesOnly: true,
      favorites: {favId: true},
    );
    expect(list.length, 1);
    expect(list.first.id, favId);
  });

  test('filterExerciseList filters by muscle group', () {
    final list = filterExerciseList(kExercises, muscleFilter: 'chest');
    expect(list.isNotEmpty, true);
    for (final e in list) {
      expect(e.primary == 'chest' || e.secondary.contains('chest'), true);
    }
  });

  test('filterExerciseList filters by difficulty level', () {
    final list = filterExerciseList(kExercises, difficultyFilter: 'Beginner');
    expect(list.isNotEmpty, true);
    for (final e in list) {
      expect(e.difficulty, 'Beginner');
    }
  });

  test('filterExerciseList combines multiple filters cleanly', () {
    final list = filterExerciseList(
      kExercises,
      muscleFilter: 'chest',
      difficultyFilter: 'Beginner',
      query: 'press',
    );
    for (final e in list) {
      expect(e.primary == 'chest' || e.secondary.contains('chest'), true);
      expect(e.difficulty, 'Beginner');
      expect(e.name.toLowerCase().contains('press'), true);
    }
  });
}
