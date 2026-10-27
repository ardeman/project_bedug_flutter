import 'package:bedug/core/utils/hijri_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an adjustment moves the Hijri date and its inverse together', () {
    final day = DateTime(2026, 10, 27);
    final calculated = hijriOf(day);
    for (final adjustment in hijriAdjustmentOptions) {
      final adjusted = hijriOf(day, adjustment);
      expect(
        hijriToGregorian(adjusted, adjustment),
        day,
        reason: '$adjustment',
      );
      expect(
        hijriToGregorian(adjusted).difference(hijriToGregorian(calculated)),
        Duration(days: adjustment),
        reason: '$adjustment',
      );
    }
  });
}
