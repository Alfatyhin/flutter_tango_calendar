import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tango_calendar/models/Event.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../icalendar_parser.dart';

class FbEventsRepository {

  Future<void> getEventsList(String url) async {
    var dataJson;

      final response = await Dio().get(url);

      if (response.statusCode == 200) {
        dataJson = response.data;

        setLocalDataJson('fbEvents', dataJson);
      }

    return dataJson;
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

  Future<String?> getLocalDataString(key) async {
    final prefs = await SharedPreferences.getInstance();
    String? string;
    if (prefs.containsKey(key)) {
      string = await prefs.getString(key);
    } else {
      string = '';
    }
    return string;
  }

}