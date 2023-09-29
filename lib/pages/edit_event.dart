import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tango_calendar/models/Calendar.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../AppTools.dart';
import '../repositories/calendar/calendar_repository.dart';
import '../utils.dart';
import 'package:intl/intl.dart';


class EditEvent extends StatefulWidget {
  const EditEvent({Key? key}) : super(key: key);

  @override
  _EditEventState createState() => _EditEventState();
}

enum EventChangeMode { one, after, all }

class _EditEventState extends State<EditEvent> {

  EventChangeMode? _changeMode = EventChangeMode.one;
  String changeMode = "one";


  final GlobalKey<FormState> _form = GlobalKey();
  TextEditingController calendarNameController = TextEditingController();
  TextEditingController eventTitleController = TextEditingController();
  TextEditingController eventDescriptionController = TextEditingController();
  TextEditingController eventLocationnController = TextEditingController();
  TextEditingController dateStartStringController = TextEditingController();
  TextEditingController dateEndStringController = TextEditingController();
  TextEditingController timeStartStringController = TextEditingController();
  TextEditingController timeEndStringController = TextEditingController();

  var eventRepeat = false;

  String _timezone = 'Unknown';
  DateTime dateStart = DateTime.now();
  DateTime dateEnd = DateTime.now();

  var userPermissions = {};

  var GlobalAddEventPermission = GlobalPermissions().addEventToCalendar;

  List iterateRules = [];
  int iterableRuleIndexActive = 0;


  var selectCalendarId;

  int _selectedIndex = 0;


  Future dateDialog(DateTime DateTimeStart, String comand){
    return  showDialog(
      context: context,
      builder: (_) =>  Dialog(
        child: Container(
          height: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                child: CalendarDatePicker(

                    initialCalendarMode: DatePickerMode.day,
                    initialDate: DateTimeStart,
                    firstDate: DateTime.now(),
                    lastDate: kLastDay,
                    onDateChanged: (DateTime value) {
                      Navigator.of(context).pop();
                      if (comand == 'start') {
                        dateStart = value;
                        dateStartStringController.text = DateFormatDate(dateStart);
                        if (dateEnd.isBefore(dateStart)) {
                          dateEnd = dateStart;
                          dateEndStringController.text = DateFormatDate(dateEnd);
                        }
                      } else {

                        dateEnd = value;
                        dateEndStringController.text = DateFormatDate(dateEnd);
                        if (dateEnd.isBefore(dateStart)) {
                          dateStart = dateEnd;
                          dateStartStringController.text = DateFormatDate(dateStart);
                        }

                      }
                      setIterableRules();
                      setState(() {

                      });
                    }
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                      onPressed: () => {
                        Navigator.of(context).pop()
                      },
                      child: Text(AppLocalizations.of(context)!.close)
                  ),
                ],
              )

            ],
          ),
        ),
      ),
      anchorPoint: Offset(1000, 1000),
    );
  }



  Future recurenceDialog(){

    return  showDialog(
      context: context,
      builder: (_) =>  Dialog(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container (
                margin: EdgeInsets.all(20),
                child:
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Column(
                      children: [

                        Text("only this"),

                        Radio<EventChangeMode>(
                          value: EventChangeMode.one,
                          groupValue: _changeMode,
                          onChanged: (EventChangeMode? value) {
                            setState(() {
                              _changeMode = value;
                              changeMode = "one";
                              Navigator.of(context).pop();
                              recurenceDialog();
                            });
                          },
                        ),
                      ],
                    ),


                    if (eventRepeat)
                      Column(
                        children: [

                          Text("this and after"),

                          Radio<EventChangeMode>(
                            value: EventChangeMode.after,
                            groupValue: _changeMode,
                            onChanged: (EventChangeMode? value) {
                              setState(() {
                                _changeMode = value;
                                changeMode = "after";
                                Navigator.of(context).pop();
                                recurenceDialog();
                              });
                            },
                          ),
                        ],
                      ),

                    if (eventRepeat)
                      Column(
                        children: [

                          Text("all"),

                          Radio<EventChangeMode>(
                            value: EventChangeMode.all,
                            groupValue: _changeMode,
                            onChanged: (EventChangeMode? value) {
                              setState(() {
                                _changeMode = value;
                                changeMode = "all";
                                Navigator.of(context).pop();
                                recurenceDialog();
                              });
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Container (
                margin: EdgeInsets.only(top: 0, left: 20.0, right: 10.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      ElevatedButton(
                          onPressed: ()  {
                            Navigator.of(context).pop();
                            addEvent();
                          },
                          child: Text('change')),

                      ElevatedButton(
                          onPressed: ()  {
                            Navigator.of(context).pop();
                          },
                          child: Text('close'))

                    ]
                ),
              )
            ],
          ),
        ),
      ),
      anchorPoint: Offset(1000, 1000),
    );
  }

  Future<void> showTimeDialog(timeCommand) async {

    DateTime timeData;
    if (timeCommand == 'start') {
      timeData = DateTime.parse("${openEvent.dateStart} ${openEvent.timeStart}");
    } else {
      timeData = DateTime.parse("${openEvent.dateEnd} ${openEvent.timeEnd}");
    }

    TimeOfDay timeDay = TimeOfDay.fromDateTime(timeData);

    final TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: timeDay,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (result != null) {

      var hour = "${result.hour}";
      if (result.hour < 10) {
        hour = "0${result.hour}";
      }
      var minute = "${result.minute}";
      if (result.minute < 10) {
        minute = "0${result.minute}";
      }
      var time = "$hour:$minute";

      if (timeCommand == 'start') {
        timeStartStringController.text = time;
      } else {
        timeEndStringController.text = time;
      }
      setState(() {});
    }
  }

  Future<void> initTimezone() async {
    return FlutterTimezone.getLocalTimezone().then((value) {
      setState(() {
        _timezone = value;
      });
    });
  }

  Future<void> getUserPermissions() async {
    if (autshUserData.role != 'user') {
      userPermissions = await CalendarRepository().getUserCalendarsPermissions(autshUserData.uid);
      print(userPermissions);
    }
  }

  void setEventData() {
    eventTitleController.text = openEvent.name;
    eventDescriptionController.text = openEvent.descriptionString();
    eventLocationnController.text = openEvent.locationString();
    dateStartStringController.text = openEvent.dateStart;
    dateEndStringController.text = openEvent.dateEnd;
    timeStartStringController.text = openEvent.timeStart;
    timeEndStringController.text = openEvent.timeEnd;

    dateStart = DateTime.parse(openEvent.dateStart);
    dateEnd = DateTime.parse(openEvent.dateEnd);
    var uidData = openEvent.eventId.split('_');

    if (uidData.length > 1) {
      eventRepeat = true;
    }
  }

  @override
  void initState() {
    super.initState();
    initTimezone();
    getUserPermissions();
    setEventData();
  }


  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(AppLocalizations.of(context)!.editEvenT),
          ),
          actions: [

          ],
        ),
        body: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Form(
            key: _form,
            child: ListView(
              children: [

                const SizedBox(height: 20.0),

                TextFormField(
                  minLines: 1,
                  maxLines: 2,
                  controller: eventTitleController,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(),
                    hintText: AppLocalizations.of(context)!.eventTitlE,
                    labelText: AppLocalizations.of(context)!.eventTitlE,
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                if (eventRepeat)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.eventRepeated)
                        ],
                      ),
                      const SizedBox(height: 20.0),
                    ],
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded (
                      child: GestureDetector(
                        onTap: () {
                          if (!eventRepeat)
                            dateDialog(dateStart, 'start');
                        },
                        child: TextFormField(
                          enabled: false,
                          controller: dateStartStringController,
                          decoration: InputDecoration(
                            label: Text(AppLocalizations.of(context)!.dateStart, style: TextStyle(
                                color: Colors.black
                            ),),
                            disabledBorder: OutlineInputBorder(),
                            hintText: AppLocalizations.of(context)!.dateStart,
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    Expanded (
                      child: GestureDetector(
                        onTap: () {
                          if (!eventRepeat)
                            dateDialog(dateEnd, 'end');
                        },
                        child: TextFormField(
                          enabled: false,
                          controller: dateEndStringController,
                          decoration: InputDecoration(
                            label: Text(AppLocalizations.of(context)!.dateEnd, style: TextStyle(
                                color: Colors.black
                            ),),
                            disabledBorder: OutlineInputBorder(),
                            hintText: AppLocalizations.of(context)!.dateEnd,
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded (
                      child: GestureDetector(
                        onTap: () {
                          showTimeDialog('start');
                        },
                        child: TextFormField(
                          enabled: false,
                          controller: timeStartStringController,
                          decoration: InputDecoration(
                            label: Text(AppLocalizations.of(context)!.timeStart, style: TextStyle(
                                color: Colors.black
                            ),),
                            disabledBorder: OutlineInputBorder(),
                            hintText: AppLocalizations.of(context)!.timeStart,
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    Expanded (
                      child: GestureDetector(
                        onTap: () {
                          showTimeDialog('end');
                        },
                        child: TextFormField(
                          enabled: false,
                          controller: timeEndStringController,
                          decoration: InputDecoration(
                            label: Text(AppLocalizations.of(context)!.timeEnd, style: TextStyle(
                                color: Colors.black
                            ),),
                            disabledBorder: OutlineInputBorder(),
                            hintText: AppLocalizations.of(context)!.timeEnd,
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                const SizedBox(height: 20.0),
                TextFormField(
                  controller: eventLocationnController,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(),
                    hintText: AppLocalizations.of(context)!.eventLocatioN,
                    labelText: AppLocalizations.of(context)!.eventLocatioN,
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    return null;
                  },
                ),


                const SizedBox(height: 20.0),

                Container(
                  height: 200,
                  child: TextField(
                    controller: eventDescriptionController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.eventDescriptioN
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    expands: true, // <-- SEE HERE
                  ),
                ),

                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    if (_form.currentState!.validate()) {
                      if (eventRepeat) {
                        recurenceDialog();
                      } else {
                        addEvent();
                      }
                    } else {
                      shortMessage(context, "error form field", 2);
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context)!.changeEvent,
                    style: TextStyle(fontSize: 24),
                  ),
                ),


              ],
            ),
          ),
        ),

        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: AppLocalizations.of(context)!.home,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.delete, size: 0,),
              label: '',
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.refresh),
                label: AppLocalizations.of(context)!.update
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.lightBlueAccent[800],
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  void addEvent() {

    ApiSigned().then((signedData) {

      var dtStart = DateTime.parse("${dateStartStringController.text}T${timeStartStringController.text}");
      var dtEnd = DateTime.parse("${dateEndStringController.text}T${timeEndStringController.text}");

      var requestTokenData = {
        'tokenId': signedData['tokenId'],
        'signed': '${signedData['signed']}',
        'calendarId': openEvent.calendarId,
        'eventId': openEvent.eventId,
        'changeMode': changeMode,
        'event': {
          "name": eventTitleController.text,
          "location": eventLocationnController.text,
          "description": eventDescriptionController.text,
          "start": {
            'dateTime': "${DateFormatDate(dtStart)}T${NumFormat(dtStart.hour)}:${NumFormat(dtStart.minute)}:00-00:00",
            'timeZone': 'Europe/London',
          },
          "end": {
            'dateTime': "${DateFormatDate(dtEnd)}T${NumFormat(dtEnd.hour)}:${NumFormat(dtEnd.minute)}:00-00:00",
            'timeZone': 'Europe/London',
          },
          'organizer': {
            'displayName': autshUserData.name,
            'email': autshUserData.email
          }
        }
      };

      // print(requestTokenData);
      // CalendarRepository().testRequest(requestTokenData);

      CalendarRepository().apiUpdateEvent(requestTokenData).then((request) {

        if (request.containsKey('errorMessage')) {
          debugPrint("error message - ${request['errorMessage']}");
          shortMessage(context, "error - ${request['errorMessage']['error']['message']}", 2);
        } else {

          shortMessage(context, "event updated", 2);
          backCommand['comand'] = 'refresh';
          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

        }
      });


    });
  }

  void setIterableRules() {

    var start = DateTime(dateStart.year, dateStart.month, 1);
    var wDayText = DateFormat.E('en').format(dateStart);
    wDayText = wDayText.substring(0, 2).toUpperCase();
    var xm = 1;
    var weekXm = xm;

    while(start.month == dateStart.month) {
      var endWeekPeriod = start.add(Duration(days: 7));
      if (dateStart.day >= start.day && dateStart.isBefore(endWeekPeriod)) {
        weekXm = xm;
      }
      xm++;
      start = endWeekPeriod;
    }

    String monWeekTitle = '$weekXm';

    if ( dateStart.add(Duration(days: 7)).month != dateStart.month) {
      weekXm = -1;
      monWeekTitle = AppLocalizations.of(context)!.lastWeekDay(wDayText);
    }

    if (weekXm == 1) {
      monWeekTitle = AppLocalizations.of(context)!.firstWeekDay(wDayText);
    } else if (weekXm == 2) {
      monWeekTitle = AppLocalizations.of(context)!.secondWeekDay(wDayText);
    } else if (weekXm == 3) {
      monWeekTitle = AppLocalizations.of(context)!.thirdWeekDay(wDayText);
    } else if (weekXm == 4) {
      monWeekTitle = AppLocalizations.of(context)!.fourthWeekDay(wDayText);
    } else if (weekXm == 5) {
      monWeekTitle = 'fifth';
    }


    iterateRules = [
      {
        'title': AppLocalizations.of(context)!.newer,
        'value': '',
        'checked': false
      },
      {
        'title': "${AppLocalizations.of(context)!.weekly} ${AppLocalizations.of(context)!.eweryWeekDay(wDayText)} \n${AppLocalizations.of(context)!.weekDay(wDayText)}",
        'value': 'RRULE:FREQ=WEEKLY;BYDAY=$wDayText',
        'checked': false
      },
      {
        'title': '${AppLocalizations.of(context)!.monthly} ${AppLocalizations.of(context)!.eweryWeekDay(wDayText)} \n$monWeekTitle ${AppLocalizations.of(context)!.weekDay(wDayText)}',
        'value': 'RRULE:FREQ=MONTHLY;BYDAY=$weekXm$wDayText',
        'checked': false
      }
    ];

    iterateRules[iterableRuleIndexActive]['checked'] = true;
  }

  void _onItemTapped(int index) async {
    switch (index) {
      case 0:
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
      case 1:

        break;
      case 2:

        setEventData();
        break;
    }

  }

}

