import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tango_calendar/models/Calendar.dart';

import '../repositories/calendar/calendar_repository.dart';

class CalendarsPage extends StatefulWidget {
  const CalendarsPage({Key? key}) : super(key: key);

  @override
  _CalendarsPageState createState() => _CalendarsPageState();
}


List<TypeEvent> generateItems() {
  List typesEventsList = ['festivals', 'master classes', 'milongas', 'tango schools'];
  List<TypeEvent> types = [];
  typesEventsList.forEach((element) {
    print(element);
    var type = TypeEvent(headerValue: element);
    types.add(type);
  });

  return types;
}


class _CalendarsPageState extends State<CalendarsPage> {

  final List<TypeEvent> _dataTypes = generateItems();
  List calendarsList = [];
  List festivals = [];
  List masterClasses = [];
  List milongas = [];
  List tangoSchools = [];
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

      _dataTypes[0].eventCalendars = festivals;
      _dataTypes[1].eventCalendars = masterClasses;
      _dataTypes[2].eventCalendars = milongas;
      _dataTypes[3].eventCalendars = tangoSchools;

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
            body:  Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  }, child: Text('на главную',
                  style: TextStyle(
                      fontSize: 20
                  ),)
                ),
                ElevatedButton(onPressed: () async {
                  await CalendarRepository().clearLocalDataJson('calendars');
                  await CalendarRepository().clearLocalDataJson('selectedCalendars');
                  setState(() {});
                  }, child: Text('очистить список салендарей',
                  style: TextStyle(
                      fontSize: 20
                  ),)
                )
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
          child: Text('Calendars'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: _menuOpen,
          )
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


  Widget _buildPanel() {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _dataTypes[index].isExpanded = !isExpanded;
        });
      },
      children: _dataTypes.map<ExpansionPanel>((TypeEvent item) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text(
                item.headerValue,
                style: TextStyle(
                  fontSize: 20
              ),),
            );
          },
          body: Container(
            child:  ListView.separated(
              itemCount: item.eventCalendars.length,
              padding: EdgeInsets.only(left: 20),
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              separatorBuilder: (BuildContext context, int index) => Divider(
                height: 20,
                color: Colors.blueAccent,
                thickness: 3,
              ),
              itemBuilder: (BuildContext context, int index) {
                return Row(
                  textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(calendarsList[item.eventCalendars[index]].name,
                      style: TextStyle(
                          fontSize: 15
                      ),),
                    Checkbox(value: calendarsList[item.eventCalendars[index]].enable, onChanged: (bool? newValue) {
                      setState(() {
                        calendarsList[item.eventCalendars[index]].enable = newValue!;
                      });
                      selectCalendar();
                    })
                  ],
                );
              },
            ),
          ),
          isExpanded: item.isExpanded,
        );
      }).toList(),
    );
  }

}

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
