import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tango_calendar/models/Calendar.dart';
import 'package:tango_calendar/models/Event.dart';
import '../../AppTools.dart';
import '../localRepository.dart';
import '../../utils.dart';

class CalendarRepository {

  final String apiUrl = 'https://tango-calendar.it-alex.net.ua';


  Future<void> addNewCalendarToFirebase(Calendar calendar) async {
    final data = calendar.toFirestore();
    db.collection('calendars')
        .doc(calendar.id)
        .set(data)
        .onError((e, _) => print("Error writing document: $e"));

  }


  Future<Map> addGCalendarToApi(requestTokenData) async {
    final response = await Dio().post('${apiUrl}/api/add_calendar', data: requestTokenData);

    var dataJson = response.data;
    print(dataJson);
    Map data = json.decode(dataJson);

    return data;
  }

  Future<String> addImportEventData(data) async {

    var key = "${data['eventImportSourceId']}-${data['eventExportId']}";
    print(key);
    return db.collection('calendarsImports')
        .doc(key)
        .set(data)
        .then((documentSnapshot) {
      return "Added import data sugess";
    }).onError((e, _) {
      print(e);
      return "error add import data";
    });
  }

  Future<List> getImportEventDataIds(List fbEventsIdsList) async {

    return db.collection('calendarsImports')
        .where('eventExportId', whereIn: fbEventsIdsList)
        .get().then(
          (querySnapshot) {
        List data = [];
        print("Successfully completed");
        for (var docSnapshot in querySnapshot.docs) {
          data.add(docSnapshot.data());
        }
        return data;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<List> getExportEventDataIds(List fbEventsIdsList) async {

    return db.collection('calendarsImports')
        .where('eventImportId', whereIn: fbEventsIdsList)
        .get().then(
          (querySnapshot) {
        List data = [];
        print("Successfully completed");
        for (var docSnapshot in querySnapshot.docs) {
          data.add(docSnapshot.data());
        }
        return data;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<List> getImportEventData(eventId) async {

    return db.collection('calendarsImports')
        .where('eventExportId', isEqualTo: eventId)
        .get().then(
          (querySnapshot) {
        List data = [];
        print("Successfully completed");
        for (var docSnapshot in querySnapshot.docs) {
          data.add(docSnapshot.data());
        }
        return data;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<List> getExportEventData(eventId) async {

    return db.collection('calendarsImports')
        .where('eventImportId', isEqualTo: eventId)
        .get().then(
          (querySnapshot) {
        List data = [];
        print("Successfully completed");
        for (var docSnapshot in querySnapshot.docs) {
          data.add(docSnapshot.data());
        }
        return data;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<List> deleteImportEventDataOld(eventId) async {

    return db.collection('calendarsImports')
        // .where('hashEvent', isNotEqualTo: true)
        .where('eventExportId', isEqualTo: eventId)
        .get().then(
          (querySnapshot) {
        List data = [];
        print("Successfully completed");
        for (var docSnapshot in querySnapshot.docs) {
          Map docData = docSnapshot.data();
          data.add(docSnapshot.data());
          if (!docData.containsKey('hashEvent')) {
            db.collection('calendarsImports').doc(docSnapshot.id).delete();
            print(docSnapshot.id);
          }
        }
        return data;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<Map> getEventsList() async {

    var res = {};
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
                for(var i = 0; i < value.length; i++) {
                  value[i]['calId'] = calendarId;
                }

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

  Future<Map> getEventsListForMonth(date) async {
    var dateFormat = DateFormatDate(date);
    Map<dynamic, dynamic> res = {};
    var dataJson;
    Map dataSaver = {};

    List selectedCalendars = [];
    Map<DateTime, List<Event>> kEventSource = {};
    var selectedCalendarsJson = await CalendarRepository().getLocalDataJson('selectedCalendars');


    if (selectedCalendarsJson != '') {
      selectedCalendars = json.decode(selectedCalendarsJson as String);
    }

    if (selectedCalendars.length > 0) {

      var oldJson = await CalendarRepository().getLocalDataJson('eventsJson');

      if (oldJson != '') {
        dataSaver = json.decode(oldJson as String);
      }

      for(var x = 0; x < selectedCalendars.length; x++) {
        var calendarId = selectedCalendars[x];

        try {
          var response = await Dio().get('${apiUrl}/api/get/events/$calendarId?month=$dateFormat');

          if (response.statusCode == 200) {
            dataJson = response.data;

            if (dataJson is String) {
              var data = json.decode(dataJson);
              if (data is Map) {
                data.forEach((key, value) {
                  for(var i = 0; i < value.length; i++) {
                    value[i]['calId'] = calendarId;
                  }

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
        } catch(e) {
          print('test error');
          res['error'] = e.toString();
          print(e.toString());
          return res;
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
    var querySnapshot = await db.collection("calendars").orderBy('country')
        .withConverter(
      fromFirestore: Calendar.fromFirestore,
      toFirestore: (Calendar calendar, _) => calendar.toFirestore(),
    ).get();
    
    List calendars = [];
    print("Successfully completed");
    for (var docSnapshot in querySnapshot.docs) {
      var calendarData = docSnapshot.data().toJson();
      calendars.add(calendarData);
    }
    var dataJson = json.encode(calendars);

    if (dataJson is String) {
      setLocalDataJson('calendars', dataJson);
    } else {
      print('is not string');
    }
  }


  Future<String> getApiServerTimeSigned() async {
    final response = await Dio().get('${apiUrl}/api/get_time_signed');

    return response.data;
  }


  Future<Map> getApiToken(requestTokenData) async {
    final response = await Dio().post('${apiUrl}/api/get/user_token', data: requestTokenData);

    var dataJson = response.data;
    print(dataJson);
    Map data = json.decode(dataJson);

    return data;
  }


  Future<Map> apiAddEvent(requestTokenData) async {
    final response = await Dio().post('${apiUrl}/api/event_add', data: requestTokenData);
    Map data = {};
    var dataJson = response.data;
    print(dataJson);
    data = json.decode(dataJson);

    return data;
  }


  Future<Map> apiUpdateEvent(requestTokenData) async {
    final response = await Dio().post('${apiUrl}/api/event_update', data: requestTokenData);
    Map data = {};
    var dataJson = response.data;
    print(dataJson);
    data = json.decode(dataJson);

    return data;
  }


  Future<Map> apiGetCalendarDataBuUid(uid) async {
    final response = await Dio().get('${apiUrl}/api/get_calendar_data_bu_uid/${uid}');
    Map data = {};
    var dataJson = response.data;
    print(dataJson);
    data = json.decode(dataJson);

    return data;
  }


  Future<String> changeCalendarData(calId, fieldName, fieldValue) async {
    print('change ${fieldName}');
    return db.collection("calendars")
        .doc(calId,)
        .update({'${fieldName}': fieldValue})
        .then((value) {
      print("Calendar Updated");
      return 'Calendar Updated';
    }).catchError((error) {
      print("Failed to update Calendar: $error");
      return 'Failed to update Calendar';
    });
  }

  void testRequest(requestTokenData) async {
    final response = await Dio().post('https://webhook.site/491a5c65-c7bd-4563-a8c7-b2d989dcd38e', data: requestTokenData);
  }


  Future<Map> apiDeleteEvent(requestTokenData) async {
    Map data = {};
    final response = await Dio().post('${apiUrl}/api/event_delete', data: requestTokenData);
    var dataJson = response.data;

    print(dataJson);
    data = json.decode(dataJson);
    return data;
  }


  Future<void> importDeleteEvent(calId, eventId) async {
    return db.collection("calendarsImports")
        .where('eventImportId', isEqualTo: eventId)
        .where('eventImportSourceId', isEqualTo: calId)
        .get().then(
          (querySnapshot) {

        for (var docSnapshot in querySnapshot.docs) {
          var importDataId = docSnapshot.id;
          db.collection("calendarsImports").doc(importDataId).delete().then(
                (doc) => print("Document deleted"),
            onError: (e) => print("Error updating document $e"),
          );
        }


      },
      onError: (e) => print("Error updating document $e"),
    );
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
            eventData['organizerName'],
            eventData['calId'],
            eventData['url']
        );
        if(eventData.containsKey('colorHash'))
        cEvent.setColorHash(eventData['colorHash']);
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

  Future<String?> getLocalDataJson(key)  {
    var json = localRepository().getLocalDataString(key);
    return json;
  }

  Future<Map> getUserCalendarsPermissions(userUid) {
    return db.collection("calendarPermissions").where('userUid', isEqualTo: userUid)
        .get()
        .then(
          (querySnapshot) {
        Map data = {};
        print("Successfully completed");
        for (var docSnapshot in querySnapshot.docs) {
          var doc = docSnapshot.data();
          data[doc['calId']] = {
            'add': doc['add'],
            'redact': doc['redact'],
            'delete': doc['delete']
          };
        };
        return data;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

}