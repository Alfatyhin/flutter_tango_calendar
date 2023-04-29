// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'dart:collection';

import 'package:tango_calendar/main.dart';

import 'models/Event.dart';
import 'package:table_calendar/table_calendar.dart';


/// Example events.
///
// /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
// var kEvents = LinkedHashMap<DateTime, List<Event>>(
//   equals: isSameDay,
//   hashCode: getHashCode,
// )..addAll(kEventSource);
//
//
//
//
// var key = DateTime.parse('2023-04-28');
// var value = Event('1', 'test event');
//
//
// var kEventSource = {key: [value]};


int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

String kLang = 'uk';
final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 6, kToday.day);
