// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:flutter_driver/src/timeline.dart';

void main() {
  group('Timeline', () {
    test('parses JSON', () {
      Timeline timeline = new Timeline.fromJson({
        'traceEvents': [
          {
            'name': 'test event',
            'cat': 'test category',
            'ph': 'B',
            'pid': 123,
            'tid': 234,
            'dur': 345,
            'ts': 456,
            'tts': 567,
            'args': {
              'arg1': true,
            }
          },
          // Tests that we don't choke on missing data
          {}
        ]
      });

      expect(timeline.events, hasLength(2));

      TimelineEvent e1 = timeline.events[0];
      expect(e1.name, 'test event');
      expect(e1.category, 'test category');
      expect(e1.phase, 'B');
      expect(e1.processId, 123);
      expect(e1.threadId, 234);
      expect(e1.duration, const Duration(microseconds: 345));
      expect(e1.timestampMicros, 456);
      expect(e1.threadTimestampMicros, 567);
      expect(e1.arguments, { 'arg1': true });

      TimelineEvent e2 = timeline.events[1];
      expect(e2.name, isNull);
      expect(e2.category, isNull);
      expect(e2.phase, isNull);
      expect(e2.processId, isNull);
      expect(e2.threadId, isNull);
      expect(e2.duration, isNull);
      expect(e2.timestampMicros, isNull);
      expect(e2.threadTimestampMicros, isNull);
      expect(e2.arguments, isNull);
    });
  });
}
