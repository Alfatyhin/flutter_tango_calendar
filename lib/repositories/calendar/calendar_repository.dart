import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tango_calendar/models/Calendar.dart';
import 'package:tango_calendar/models/Event.dart';
import '../localRepository.dart';
import '../../utils.dart';

class CalendarRepository {

  final String apiUrl = 'https://tango-calendar.it-alex.net.ua';

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
        final response = await Dio().get('${apiUrl}/api/get/events/$calendarId');

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
    final response = await Dio().get('${apiUrl}/api/get/calendars');
    var dataJson = response.data;
    setLocalDataJson('calendars', dataJson);
  }


  Future<Map> getApiToken(requestTokenData) async {
    final response = await Dio().post('${apiUrl}/api/get/user_token', data: requestTokenData);

    var dataJson = response.data;
    print(dataJson);
    Map data = json.decode(dataJson);

    return data;
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
    localRepository().clearLocalData(key);
  }

  Future setLocalDataJson(key, data) async {
    localRepository().setLocalDataString(key, data);
  }

  Future<String?> getLocalDataJson(key) async {
    var json = await localRepository().getLocalDataString(key);
    return json;
  }

}