import 'dart:collection';

// import 'package:googleapis/sheets/v4.dart';
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

String kLang = 'en';
final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
DateTime kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);

String NumFormat(int num) {
  String res = '$num';
  if (num < 10) {
    res = '0$num';
  }
  return res;
}



String DateFormatDate(DateTime date) {
  return '${date.year}-${NumFormat(date.month)}-${NumFormat(date.day)}';
}
String DateFormatTime(DateTime date) {
  return '${NumFormat(date.hour)}-${NumFormat(date.minute)}';
}
String DateFormatDateTime(DateTime date) {
  return '${date.year}-${NumFormat(date.month)}-${NumFormat(date.day)} ${NumFormat(date.hour)}:${NumFormat(date.minute)}';
}

