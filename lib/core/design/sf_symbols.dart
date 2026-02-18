import 'package:flutter/material.dart';

class SFSymbols {
  SFSymbols._();

  static IconData materialFallback(String name) {
    return switch (name) {
      'house.fill' => Icons.home,
      'house' => Icons.home_outlined,
      'calendar' => Icons.calendar_month_outlined,
      'calendar.circle.fill' => Icons.calendar_month,
      'gearshape.fill' => Icons.settings,
      'gearshape' => Icons.settings_outlined,
      'clock.fill' => Icons.access_time_filled,
      'clock' => Icons.access_time_outlined,
      'magnifyingglass' => Icons.search,
      'person.fill' => Icons.person,
      'person' => Icons.person_outline,
      _ => Icons.circle_outlined,
    };
  }
}
