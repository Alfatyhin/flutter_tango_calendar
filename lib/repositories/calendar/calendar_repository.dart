import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class CalendarRepository {

  Future<void> getEventsList() async {
    final response = await Dio().get('https://tango-calendar.it-alex.net.ua/api/getevents?test=43756');
    debugPrint(response.toString());
  }
  Future<void> getCalendarsList() async {
    final response = await Dio().get('https://tango-calendar.it-alex.net.ua/api/get/calendars');
    debugPrint(response.data);
  }

}