import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tango_calendar/models/Calendar.dart';

import '../repositories/calendar/calendar_repository.dart';

class CalendarsPage extends StatefulWidget {
  const CalendarsPage({Key? key}) : super(key: key);

  @override
  _CalendarsPageState createState() => _CalendarsPageState();
}

class _CalendarsPageState extends State<CalendarsPage> {

  List calendarsList = [];
  List festivals = [];
  List master_classes = [];
  List milongas = [];
  List tango_school = [];
  List countries = [];
  List cityes = [];

  @override
  void initState() {
    super.initState();
    setlocaleJsonData();
  }

  @override
  Future<void> setlocaleJsonData() async {
    Map selected = {};
    List selectedCalendars = [];

    var calendarsJson = await CalendarRepository().getLocalDataJson('calendars');
    var selectedCalendarsJson = await CalendarRepository().getLocalDataJson('selectedCalendars');

    if (selectedCalendarsJson != '') {
      selectedCalendars = json.decode(selectedCalendarsJson as String);
    }
    if (selectedCalendars.length > 0) {
      for(var x = 0; x < selectedCalendars.length; x++) {
        var key = selectedCalendars[x] as String;
        selected[key] = true;
      }
      print(selected);
    } else {
      print('not selected');
    }

    if (calendarsJson != '') {
      Map data = json.decode(calendarsJson as String);

      Map calendarsData = data['calendars'];

      int xl = 0;
      calendarsData.forEach((key, value) {
        var calendar = Calendar(
            key,
            value['name'],
            value['description'],
            value['type_events'],
            value['country'],
            value['city'],
            value['source']
        );

        if (selectedCalendars.length > 0 && selected.containsKey(key)) {
          print('${calendar.name} +');
          calendar.enable = true;
        }

        calendarsList.add(calendar);
        countries.add(value['country']);
        cityes.add(value['city']);

        switch(value['type_events']) {
          case 'festivals':
            festivals.add(xl);
            break;
          case 'master_classes':
            master_classes.add(xl);
            break;
          case 'milongas':
            milongas.add(xl);
            break;
          case 'tango_school':
            tango_school.add(xl);
        }
        xl++;
      });

      setState(() {});

    }
  }

  void selectCalendar() {
    List selected = [];
    for(var x = 0; x < calendarsList.length; x++) {
      var enable = calendarsList[x].enable;
      if (enable) {
        selected.add(calendarsList[x].id);
      }
    }
    var data = json.encode(selected);
    CalendarRepository().setLocalDataJson('selectedCalendars', data);
  }

  void _menuOpen() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: Text('Меню'),),
            body: Column(
              children: [
                ElevatedButton(onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }, child: Text('на главную')),
                ElevatedButton(onPressed: () async {
                  await CalendarRepository().clearLocalDataJson('eventsJson');
                  setState(() {});
                }, child: Text('очистить список салендарей'))
              ],
            ),
          );
        })
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Список календарей'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: _menuOpen,
          )
        ],
      ),
      body: ListView.builder(
          itemCount: calendarsList.length,
          padding: EdgeInsets.only(left: 20),
          itemBuilder: (BuildContext context, int index) {
            return Row(
              textDirection: TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(calendarsList[index].name,
                style: TextStyle(
                  fontSize: 20
                ),),
                Checkbox(value: calendarsList[index].enable, onChanged: (bool? newValue) {
                  setState(() {
                    calendarsList[index].enable = newValue!;
                  });
                  selectCalendar();
                })
              ],
            );
          }
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.update),
        onPressed: () async {
          await CalendarRepository().updateCalendarsData();
          print('calendars updated');
          setlocaleJsonData();
          setState(() {});
        }
        ,),
    );
  }
}


