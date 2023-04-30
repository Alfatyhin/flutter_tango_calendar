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
    final response = await Dio().get('https://tango-calendar.it-alex.net.ua/api/get/events/14');

    var res;
    var key = DateTime.now();
    var value = Event('1', 'test event', 'test event', 'test event', 0, 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'test event');
    var kEventSource = {key: [value]};

    if (response.statusCode == 200) {
      var dataJson = response.data;
      setLocalDataJson('eventsJson', dataJson);
      
      if (dataJson is String) {
        var data = json.decode(dataJson);
        if (data is Map) {
          kEventSource = getJsonDataEventsMap(data);

          /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
          res = LinkedHashMap<DateTime, List<Event>>(
            equals: isSameDay,
            hashCode: getHashCode,
          )..addAll(kEventSource);

        }
      }
    }

    return res;
  }


  Future<void> getCalendarsList() async {
    final response = await Dio().get('https://tango-calendar.it-alex.net.ua/api/get/calendars');
    final data = response.data;
    print(data);
    // final dataList = data.entries.map((e) => Calendar(
    //     name: e.name,
    //     description,
    //     type_events,
    //     country,
    //     city,
    //     source
    // ));
    //
    // return dataList;
  }

  Map<DateTime, List<Event>> getJsonDataEventsMap(data) {

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