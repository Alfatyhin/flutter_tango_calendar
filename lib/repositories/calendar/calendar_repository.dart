import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tango_calendar/models/Calendar.dart';
import 'package:tango_calendar/models/Event.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils.dart';

class CalendarRepository {

  Future<Map> getEventsList() async {

    var res;
    var dataJson;
    Map dataSaver = {};

    List selectedCalendars = [];
    Map<DateTime, List<Event>> kEventSource = {};
    var selectedCalendarsJson = await CalendarRepository().getLocalDataJson('selectedCalendars');

    if (selectedCalendarsJson != '') {
      selectedCalendars = json.decode(selectedCalendarsJson as String);
    }
    if (selectedCalendars.length > 0) {

      for(var x = 0; x < selectedCalendars.length; x++) {
        var calendarId = selectedCalendars[x];
        final response = await Dio().get('https://tango-calendar.it-alex.net.ua/api/get/events/$calendarId');

        if (response.statusCode == 200) {
          dataJson = response.data;

          if (dataJson is String) {
            var data = json.decode(dataJson);
            if (data is Map) {
              data.forEach((key, value) {
                if (dataSaver.containsKey(key)) {
                  List oldData = dataSaver[key];
                  oldData.addAll(value);
                  dataSaver[key] = oldData;
                } else {
                  dataSaver[key] = value;
                }
              });

            }
          }
        }
      }
      kEventSource = getKeventToDataMap(dataSaver);

      /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
      res = LinkedHashMap<DateTime, List<Event>>(
        equals: isSameDay,
        hashCode: getHashCode,
      )..addAll(kEventSource);

      dataJson = json.encode(dataSaver);
      setLocalDataJson('eventsJson', dataJson);

    }

    return res;
  }


  Future<void> updateCalendarsData() async {
    final response = await Dio().get('https://tango-calendar.it-alex.net.ua/api/get/calendars');
    var dataJson = response.data;
    setLocalDataJson('calendars', dataJson);
  }

  Map<DateTime, List<Event>> getKeventToDataMap(data) {

    Map<DateTime, List<Event>> kEventSource = {};

    data.forEach((key, value) {
      var keyDate = DateTime.parse(key);
      List<Event> values = [];
      for(var i = 0; i < value.length; i++) {
        Map eventData = value[i];
        var cEvent = Event(
            eventData['eventId'],
            eventData['name'],
            eventData['description'],
            eventData['location'],
            eventData['timeUse'],
            eventData['dateStart'],
            eventData['timeStart'],
            eventData['dateEnd'],
            eventData['timeEnd'],
            eventData['update'],
            eventData['creatorEmail'],
            eventData['creatorName'],
            eventData['organizerEmail'],
            eventData['organizerName']
        );
        values.add(cEvent);
      }
      kEventSource[keyDate] = values;
    });

    return kEventSource;
  }

  Future clearLocalDataJson(key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future setLocalDataJson(key, data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, data);
  }

  Future<String?> getLocalDataJson(key) async {
    final prefs = await SharedPreferences.getInstance();
    String? json;
    if (prefs.containsKey(key)) {
      json = await prefs.getString(key);
    } else {
      json = '';
    }
    return json;
  }

}