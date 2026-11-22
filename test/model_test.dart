import 'dart:math';

import 'package:blood_request/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates required data, eight groups, and localized phone digits', () {
    expect(const PosterRequest().valid, isFalse);
    for (final group in groups) {
      expect(
        PosterRequest(values: PosterRequest.sample.values, group: group).valid,
        isTrue,
      );
    }
    for (final number in [
      '0321-4567890',
      '+92 (321) 456-7890',
      '00923331234567',
      '+1 (202) 555-0198',
      '+९१ ९८७६५४३२१०',
      '۰۳۲۱-۴۵۶۷۸۹۰',
    ]) {
      expect(validPhone(number), isTrue, reason: number);
    }
    for (final number in ['+0 123456789', 'abc', '123', '12+34567890']) {
      expect(validPhone(number), isFalse);
    }
  });

  test('preserves draft data and template through versioned serialization', () {
    final draft = PosterDraft('draft', PosterRequest.sample, 11);
    final restored = PosterDraft.fromJson(draft.toJson());
    expect(restored.request.toJson(), draft.request.toJson());
    expect(restored.template, 11);
    expect(() => PosterDraft.fromJson({'version': -1}), throwsFormatException);
  });

  test('design rotation avoids the last three choices', () {
    final recent = [0, 1, 2];
    final random = Random(143);
    for (var step = 0; step < 100; step++) {
      final next = nextDesign(recent, random);
      expect(recent, isNot(contains(next)));
      recent
        ..insert(0, next)
        ..removeLast();
    }
  });
}
