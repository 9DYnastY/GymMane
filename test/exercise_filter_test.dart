import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/models/place.dart';
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

  test('filterExerciseList filters by noGearOnly (Bodyweight only)', () {
    final list = filterExerciseList(kExercises, noGearOnly: true);
    expect(list.isNotEmpty, true);
    for (final e in list) {
      expect(e.equipment, 'Bodyweight');
    }
  });

  test('filterExerciseList filters by equipmentFilter', () {
    final list = filterExerciseList(kExercises, equipmentFilter: 'Dumbbell');
    expect(list.isNotEmpty, true);
    for (final e in list) {
      expect(e.equipment, 'Dumbbell');
    }
  });

  test('filterExerciseList filters by place (gear in place + Bodyweight)', () {
    final homePlace = GymPlace(id: 'home_1', name: 'Home', equipment: {'Dumbbell', 'Band'});
    final list = filterExerciseList(
      kExercises,
      placeId: 'home_1',
      places: [homePlace],
    );
    expect(list.isNotEmpty, true);
    for (final e in list) {
      expect(e.equipment == 'Dumbbell' || e.equipment == 'Band' || e.equipment == 'Bodyweight', true);
    }
  });

  test('filterExerciseList combines multiple filters cleanly', () {
    final homePlace = GymPlace(id: 'home_1', name: 'Home', equipment: {'Dumbbell', 'Band'});
    final list = filterExerciseList(
      kExercises,
      placeId: 'home_1',
      places: [homePlace],
      muscleFilter: 'chest',
      equipmentFilter: 'Dumbbell',
      difficultyFilter: 'Beginner',
      query: 'press',
    );
    for (final e in list) {
      expect(e.primary == 'chest' || e.secondary.contains('chest'), true);
      expect(e.difficulty, 'Beginner');
      expect(e.equipment, 'Dumbbell');
      expect(e.name.toLowerCase().contains('press'), true);
    }
  });

  test('filterExerciseList supports exercise abbreviation aliases', () {
    final list = filterExerciseList(kExercises, query: 'db bench');
    expect(list.isNotEmpty, true);
    for (final e in list) {
      expect(e.name.toLowerCase().contains('dumbbell') && e.name.toLowerCase().contains('bench'), true);
    }
  });
}
