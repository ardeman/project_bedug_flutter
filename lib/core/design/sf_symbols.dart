import 'package:flutter/cupertino.dart';

import 'platform_capabilities.dart';

class SFSymbols {
  SFSymbols._();

  static IconData? resolve(String name) {
    if (!PlatformCapabilities.isIOS) return null;
    return switch (name) {
      'house.fill' => CupertinoIcons.house_fill,
      'house' => CupertinoIcons.house,
      'calendar' => CupertinoIcons.calendar,
      'calendar.circle.fill' => CupertinoIcons.calendar_circle_fill,
      'gearshape.fill' => CupertinoIcons.gear_alt_fill,
      'gearshape' => CupertinoIcons.gear,
      'clock.fill' => CupertinoIcons.time_solid,
      'clock' => CupertinoIcons.time,
      'magnifyingglass' => CupertinoIcons.search,
      'person.fill' => CupertinoIcons.person_fill,
      'person' => CupertinoIcons.person,
      _ => null,
    };
  }
}
