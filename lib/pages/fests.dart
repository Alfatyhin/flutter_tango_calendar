import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tango_calendar/models/Calendar.dart';

import '../repositories/calendar/calendar_repository.dart';

// stores ExpansionPanel state information
class TypeEvent {
  TypeEvent({
    required this.headerValue,
    this.isExpanded = false,
  });

  String headerValue;
  bool isExpanded;
  List eventCalendars = [];

}

List<TypeEvent> generateItems() {
  List typesEventsList = ['festivals', 'masterClasses', 'milongas', 'tangoSchool'];
  List<TypeEvent> types = [];
  typesEventsList.forEach((element) {
    print(element);
    var type = TypeEvent(headerValue: element);
    types.add(type);
  });

  return types;
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {

  final List<TypeEvent> _data = generateItems();
  List calendarsList = [];
  List festivals = [];
  List masterClasses = [];
  List milongas = [];
  List tangoSchools = [];
  List countries = [];
  List cityes = [];

  int dataIndex = 0;

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
            masterClasses.add(xl);
            break;
          case 'milongas':
            milongas.add(xl);
            break;
          case 'tango_school':
            tangoSchools.add(xl);
        }
        xl++;
      });

      _data[0].eventCalendars = festivals;
      _data[1].eventCalendars = masterClasses;
      _data[2].eventCalendars = milongas;
      _data[3].eventCalendars = tangoSchools;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Test'),
        ),
        actions: [

        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            child: _buildPanel(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.backspace),
        onPressed: ()  {
          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);
        }
        ,),
    );
  }

  Widget _buildPanel() {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        dataIndex = index;
        test(_data[index]);
        setState(() {
          _data[index].isExpanded = !isExpanded;
        });
      },
      children: _data.map<ExpansionPanel>((TypeEvent item) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text(item.headerValue),
            );
          },
          body: Container(
            child: Text('test'),
          ),
          isExpanded: item.isExpanded,
        );
      }).toList(),
    );
  }

  String test(Object data) {
    print('-------------');
    print(data.toString());
    return 'test';
  }
}
