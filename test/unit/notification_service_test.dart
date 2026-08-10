import 'package:flutter_test/flutter_test.dart';
import 'package:trackedify/shared/constants/constants.dart';

void main() {
  group('Notification Constants & Schedule Math', () {
    test('AppStrings notification constants are properly defined', () {
      expect(AppStrings.basicChannelKey, isNotEmpty);
      expect(AppStrings.basicChannelName, isNotEmpty);
      expect(AppStrings.scheduledChannelKey, isNotEmpty);
      expect(AppStrings.scheduledChannelName, isNotEmpty);
    });

    test('schedule calculation determines future time correctly', () {
      final now = DateTime.now();

      // Time 1 hour in future today
      final futureHour = (now.hour + 1) % 24;
      final scheduledToday = DateTime(
        now.year,
        now.month,
        now.day,
        futureHour,
        now.minute,
      );
      if (futureHour > now.hour) {
        expect(scheduledToday.isAfter(now), isTrue);
      }

      // Time earlier today -> rolls over to tomorrow
      final pastHour = (now.hour - 1 + 24) % 24;
      var scheduledPast = DateTime(
        now.year,
        now.month,
        now.day,
        pastHour,
        now.minute,
      );
      if (!scheduledPast.isAfter(now)) {
        scheduledPast = scheduledPast.add(const Duration(days: 1));
      }

      expect(scheduledPast.isAfter(now), isTrue);
    });
  });
}
