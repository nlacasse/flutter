// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  test("Can set value during status callback", () {
    WidgetFlutterBinding.ensureInitialized();
    AnimationController controller = new AnimationController(
      duration: const Duration(milliseconds: 100)
    );
    bool didComplete = false;
    bool didDismiss = false;
    controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        didComplete = true;
        controller.value = 0.0;
        controller.forward();
      } else if (status == AnimationStatus.dismissed) {
        didDismiss = true;
        controller.value = 0.0;
        controller.forward();
      }
    });

    controller.forward();
    expect(didComplete, isFalse);
    expect(didDismiss, isFalse);
    Scheduler.instance.handleBeginFrame(const Duration(seconds: 1));
    expect(didComplete, isFalse);
    expect(didDismiss, isFalse);
    Scheduler.instance.handleBeginFrame(const Duration(seconds: 2));
    expect(didComplete, isTrue);
    expect(didDismiss, isTrue);
  });
}