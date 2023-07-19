import 'dart:collection';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


import '../AppTools.dart';
import '../models/Calendar.dart';
import '../models/table_calendar.dart';
import '../models/Event.dart';
import '../models/UserData.dart';
import '../repositories/calendar/calendar_repository.dart';
import '../repositories/localRepository.dart';
import '../repositories/users/users_reposirory.dart';
import '../utils.dart';

late final FirebaseApp app;
late final FirebaseAuth auth;



class StartPage extends StatefulWidget {
  @override
  _StartPageState createState() => _StartPageState();
}


enum EventChangeMode { one, after, all }

class _StartPageState extends State<StartPage> {

  EventChangeMode? _changeMode = EventChangeMode.one;
  String changeMode = "one";

  var CalEvents = {};
  var userUid = '';
  var userRole = '';
  var key = DateTime.now();
  int _selectedIndex = 0;
  int _selectedIndexEventOpen = 0;
  int statmensCount = 0;
  DateTime kLastDayThis = kLastDay;

  List shortFilter = [];

  Map uploadsEventDates = {};

  Map exportData = {};
  List exportIds = [];

  void initFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp().whenComplete(() {
      print('init completed');

    });
    
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) async {
      if (user != null) {
        UserData userData = await usersRepository().getUserDataByUid(user.uid!);
        // UserData userData = await usersRepository().getUserDataByUid('');

        autshUserData = userData;
        if (autshUserData.role == 'su_admin' || autshUserData.role == 'admin') {
          usersRepository().getStatementsCount().then((value) {
            statmensCount = value;
            setState(() {});
          });
        }

        CalendarRepository().getUserCalendarsPermissions(autshUserData.uid).then((value) {
          userCalendarsPermissions = value;
        });

        if (userData.role == 'admin'
            || userData.role == 'su_admin'
            || userData.role == 'organizer') {
          kLastDayThis = DateTime(kToday.year, kToday.month + 12, kToday.day);
        } else {
          kLastDayThis = DateTime(kToday.year, kToday.month + 6, kToday.day);
        }
        setState(() {
          kLastDayThis = kLastDayThis;
          userRole = userData.role;
          userUid = userData.uid!;
        });
      } else {
        autshUserData = UserData();
      }
    });
  }


  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  late Map<DateTime, List<Event>> kEventSource;




  Future<void> firstStart() async {
    await CalendarRepository().updateCalendarsData();
    await calendarsMapped();
    List selected = [];
    shortFilter.add("3");
    selected.add("3");
    await localRepository().setLocalDataJson('shortFilter', shortFilter);
    await localRepository().setLocalDataJson('selectedCalendars', selected);
    uploadsEventDates = {};
    await updateData();
  }


  @override
  void initState() {
    super.initState();
    initFirebase();
    calendarsMapped();
    print('init state');
    kEvents = CalEvents;
    //////////////////////////////////

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));


    CalendarRepository().getLocalDataJson('selectedCalendars').then((selectedCalendarsJson) {

      print('selectedCalendars test');
      print(selectedCalendarsJson);
      CalendarRepository().getLocalDataJson('calendars').then((calendarsJson) {
        var selectedData = [];

        if (selectedCalendarsJson != '') {
          selectedData = json.decode(selectedCalendarsJson as String);
        }


        if (selectedData.length > 0) {
          selectedData = json.decode(selectedCalendarsJson as String);
          if (selectedData.length > 0) {

            if (calendarsJson != '') {
              List calendarsData = json.decode(calendarsJson as String);

              calendarsData.forEach((value) {
                var calendar = Calendar.fromLocalData(value);

                if (selectedData.contains(calendar.id)) {
                  selectedCalendars[calendar.id] = calendar;
                }

              });
            }
          }
        } else {
          print('first start');
          firstStart();
        }

      });

    });

    localRepository().getLocalDataString('shortFilter').then((value){
      if (value != '') {
        setState(() {
          shortFilter = json.decode(value as String);
        });
      }
    });

    localRepository().getLocalDataString('uploadsEventDates').then((value){
      if (value != '') {
        Map uploadsDates = json.decode(value as String);
        try {
          uploadsEventDates['minDate'] = DateTime.parse(uploadsDates['minDate']);
          uploadsEventDates['maxDate'] = DateTime.parse(uploadsDates['maxDate']);
          print(uploadsEventDates);
          setlocaleJsonData();
          // _selectedEvents.value = _getEventsForDay(_selectedDay!);
          setState(() {});
        } catch(e) {
          print(e);
        }

      }
    });


    if (backCommand['comand'] == 'refresh') {
      backCommand['comand'] = '';
      refreshCommand();
    }

  }

  Future<void> refreshCommand() async {
    uploadsEventDates = {};
    await CalendarRepository().clearLocalDataJson('eventsJson');
    updateData();
  }


  void _menuOpen() {

    var title = 'Menu';
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {

          if (userUid == '') {

            return Scaffold(
              appBar: AppBar(title: Text(title),),
              body:
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(context, '/register_user', (route) => false);
                  }, child: Text('Register',
                    style: TextStyle(
                        fontSize: 20
                    ),),),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(context, '/login_user', (route) => false);
                  }, child: Text('Login',
                    style: TextStyle(
                        fontSize: 20
                    ),),),


                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(context, '/about', (route) => false);
                  }, child: Text('about',
                    style: TextStyle(
                        fontSize: 20
                    ),),),
                ],
              ),
            );

          } else {

            return Scaffold(
              appBar: AppBar(title: Text(title),),
              body:
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(context, '/fb_events', (route) => false);
                  }, child: Text('Facebook Events',
                    style: TextStyle(
                        fontSize: 20
                    ),),),

                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () {
                    _logOut();
                    Navigator.pop(context);
                  }, child: Text('Log out',
                    style: TextStyle(
                        fontSize: 20
                    ),),),


                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(context, '/user_profile', (route) => false, arguments: userUid);
                  }, child: Text('My Profile',
                    style: TextStyle(
                        fontSize: 20
                    ),),),




                  if (autshUserData.role == 'su_admin')
                    Container(
                      child: ListView(
                        shrinkWrap: true,
                        children: [

                          const SizedBox(height: 20),
                          ElevatedButton(onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamedAndRemoveUntil(context, '/users', (route) => false);
                          }, child: Text('Users',
                            style: TextStyle(
                                fontSize: 20
                            ),),),


                          const SizedBox(height: 20),
                          ElevatedButton(onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamedAndRemoveUntil(context, '/statements', (route) => false);
                          }, child: Text('Statements',
                            style: TextStyle(
                                fontSize: 20
                            ),),),

                        ],
                      ),
                    ),


                  if (autshUserData.role == 'su_admin'
                      || autshUserData.role == 'admin'
                      || autshUserData.role == 'organizer')

                    Container(
                      child: ListView(
                        shrinkWrap: true,
                        children: [

                          const SizedBox(height: 20),
                          ElevatedButton(onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamedAndRemoveUntil(context, '/add_calendar', (route) => false);
                          }, child: Text('add calendar',
                            style: TextStyle(
                                fontSize: 20
                            ),),),
                        ],
                      ),
                    ),


                  if (autshUserData.role == 'su_admin'
                      || autshUserData.role == 'admin'
                      || autshUserData.role == 'organizer')

                    Container(
                      child: ListView(
                        shrinkWrap: true,
                        children: [

                          const SizedBox(height: 20),
                          ElevatedButton(onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamedAndRemoveUntil(context, '/create_event', (route) => false);
                          }, child: Text('create event',
                            style: TextStyle(
                                fontSize: 20
                            ),),),
                        ],
                      ),
                    ),


                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(context, '/about', (route) => false);
                  }, child: Text('About',
                    style: TextStyle(
                        fontSize: 20
                    ),),),

                ],
              ),
            );

          }


        })
    );
  }

  Future<void> _logOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      userUid = '';
    });
  }

  void _eventOpen(Event event) {
    _changeMode = EventChangeMode.one;
    changeMode = "one";
    openEvent = event;

    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: Text('event data'),),
            body: Container (
              margin: EdgeInsets.only(top: 20.0, left: 10.0, right: 10.0),
              child: ListView(
                children: [

                  Center(
                      child:  SelectableText("${event.name}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600
                          ),
                      )
                  ),
                  const SizedBox(height: 8.0),
                  Center(
                      child:  SelectableText("${event.timePeriod()}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 20),
                      ),
                  ),
                  const SizedBox(height: 8.0),
                  Center(
                      child: SelectableText("${event.locationString()}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 15),
                      ),
                  ),
                  const SizedBox(height: 8.0),


                  Center(
                      child: SelectableText("${event.descriptionString()}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 20),
                      ),
                  ),
                  const SizedBox(height: 8.0),
                  Center(
                      child: Text("${event.organizerName}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 20),
                          softWrap: true
                      ),
                  ),


                  if (autshUserData.role == 'su_admin' || autshUserData.role == 'admin')
                    Column(
                      children: [

                        const SizedBox(height: 3.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('id - ${event.eventId}',
                              style: TextStyle(
                                  fontSize: 18
                              ),)),

                            ElevatedButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: event.eventId));
                              },
                              child: Icon(Icons.copy, ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('calId - ${event.calendarId}',
                              style: TextStyle(
                                  fontSize: 18
                              ),)
                          ],
                        ),
                        const SizedBox(height: 8.0),
                      ],
                    ),

                ],
              ),
            ),

            bottomNavigationBar: BottomNavigationBar(
              items:  <BottomNavigationBarItem>[


                if ((autshUserData.role == 'su_admin' || autshUserData.role == 'admin'))
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'import',
                  )
                else
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings, color: Colors.grey[300],),
                    label: 'import',
                  ),

                if(autshUserData.role != null && ((userCalendarsPermissions.containsKey(key)
                    && userCalendarsPermissions[event.calendarId]['delete'] > 0
                    && CalendarPermEventDelete[autshUserData.role] > 1)
                    || selectedCalendars[event.calendarId].creator == autshUserData.uid
                    || CalendarPermEventDelete[autshUserData.role] > 1))

                  BottomNavigationBarItem(
                    icon: Icon(Icons.delete, color: Colors.green,),
                    label: 'delete',
                  )
                else if (userCalendarsPermissions.containsKey(event.calendarId)
                    && userCalendarsPermissions[event.calendarId]['delete'] > 0
                    && CalendarPermEventDelete[autshUserData.role] == 1)

                  BottomNavigationBarItem(
                    icon: Icon(Icons.delete, color: Colors.blue,),
                    label: 'delete',
                  )

                else

                  BottomNavigationBarItem(
                    icon: Icon(Icons.delete, color: Colors.grey[300],),
                    label: 'delete',
                  ),

                if(autshUserData.role != null && ((userCalendarsPermissions.containsKey(key)
                    && userCalendarsPermissions[event.calendarId]['redact'] > 0
                    && CalendarPermEventRedact[autshUserData.role] > 1)
                    || selectedCalendars[event.calendarId].creator == autshUserData.uid
                    || CalendarPermEventDelete[autshUserData.role] > 1))

                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long, color: Colors.green,),
                    label: 'edit',
                  )

                else if((userCalendarsPermissions.containsKey(key)
                    && userCalendarsPermissions[event.calendarId]['redact'] > 0
                    && CalendarPermEventRedact[autshUserData.role] > 1))

                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long, color: Colors.blue,),
                    label: 'edit',
                  )

                else
                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long, color: Colors.grey[300],),
                    label: 'edit',
                  )

              ],

              currentIndex: _selectedIndexEventOpen,
              selectedItemColor: Colors.lightBlueAccent[800],
              onTap: _onEventOpenItemTapped,
            ),
          );
        })
    );
  }


  Future filterCalendarsDialog(){


    List dialogList = [];
    if (shortFilter.length == 0) {
      selectedCalendars.forEach((key, calendar) {
        shortFilter.add(key);
      });
    }
    selectedCalendars.forEach((key, calendar) {
      dialogList.add(key);
    });

    return  showDialog(
      context: context,
      builder: (_) =>  Dialog(
        child: ListView(
          children: [
            ListView.builder(
                shrinkWrap: true,
                itemCount: dialogList.length,
                itemBuilder: (BuildContext context, int index) {
                  var calId = dialogList[index];

                  if (AllCalendars.containsKey(calId)) {
                    Calendar calendar = AllCalendars[calId] as Calendar;

                    return Container (
                      margin: EdgeInsets.only(top: 0, left: 20.0, right: 10.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceBetween,
                          children: [
                            Expanded(child: Text(calendar.name,
                              style: TextStyle(
                                  fontSize: 15
                              ),)),

                            Checkbox(
                                value:  shortFilter.contains(calId),
                                onChanged: (bool? newValue) {
                                  if (shortFilter.contains(calId)) {
                                    shortFilter.remove(calId);
                                  } else {
                                    shortFilter.add(calId);
                                  }
                                  localRepository().setLocalDataJson('shortFilter', shortFilter);
                                  Navigator.of(context).pop();
                                  setState(() {
                                    filterCalendarsDialog();
                                  });
                                })
                          ]
                      ),
                    );
                  } else {
                    return Container();
                  }

                }),

            if (AllCalendars.length == 0)
            Container(
              margin: EdgeInsets.only(top: 40, left: 20.0, right: 20.0, bottom: 40),
              child: Column(
                children: [
                  Text('Go to Calendars and upload Calendars List')

                ],
              ),
            ),

            Container (
              margin: EdgeInsets.only(top: 0, left: 20.0, right: 10.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    ElevatedButton(
                        onPressed: () {
                          // Navigator.pop(context);
                          Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);
                        },
                        child: Text('Calendars')
                    ),

                    ElevatedButton(
                        onPressed: ()  {
                          Navigator.of(context).pop();
                          setlocaleJsonData();
                        },
                        child: Text('close'))

                  ]
              ),
            )
          ],
        ),
      ),
      anchorPoint: Offset(1000, 1000),
    );
  }


  Future deleteEventDialog(){

    var eventRepeat = false;
    var uidData = openEvent.eventId.split('_');

    if (uidData.length > 1) {
      eventRepeat = true;
    } else {
      _changeMode = EventChangeMode.one;
      changeMode = "one";
    }

    return  showDialog(
      context: context,
      builder: (_) =>  Dialog(
        child: Center(
          child: Column(
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
                              deleteEventDialog();
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
                              deleteEventDialog();
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
                              deleteEventDialog();
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
                            deleteEvent();
                          },
                          child: Text('delete')),

                      ElevatedButton(
                          onPressed: ()  {
                            Navigator.of(context).pop();
                            setlocaleJsonData();
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


  @override
  Future<void> setlocaleJsonData() async {
     var oldJson = await CalendarRepository().getLocalDataJson('eventsJson');
     print('setlocaleJsonData');

     if (oldJson != '') {
       Map data = json.decode(oldJson as String);

       if (shortFilter.length != 0) {
         Map newData = {};
         data.forEach((key, value) {
           value as List;
           var filtersEvents = [];
           value.forEach((element) {
             if(shortFilter.contains(element['calId'])) {
               filtersEvents.add(element);
             }
           });
           if (filtersEvents.length > 0 ) {
             newData[key] = filtersEvents;
           }
         });
         data = newData;
       }

       kEventSource = CalendarRepository().getKeventToDataMap(data) as Map<DateTime, List<Event>>;

       /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
       CalEvents = LinkedHashMap<DateTime, List<Event>>(
         equals: isSameDay,
         hashCode: getHashCode,
       )..addAll(kEventSource);


       setState(() {
         print('set state');
         kEvents = CalEvents;
         _selectedEvents.value = _getEventsForDay(_selectedDay!);
       });
     }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Implementation example
    return CalEvents[day] ?? [];
  }

  Future<void> getImportData(events) async {
    print('get import Data');
    List dayEventsIds = [];
    events.forEach((element) {
      if (!exportIds.contains(element.eventId)) {
        exportIds.add(element.eventId);
        dayEventsIds.add(element.eventId);
        print(element.eventId);
      }
    });


    while(dayEventsIds.length > 0 ) {
      print('test');
      int size = 10;
      if (dayEventsIds.length < 10) {
        size = dayEventsIds.length;
      }
      List list = dayEventsIds.sublist(0, size);

      dayEventsIds.removeRange(0, size);

      var result = await CalendarRepository().getExportEventDataIds(list);

      result.forEach((element) {
        String evId = element['eventImportId'];
        if (!exportData.containsKey(evId)) {
          exportData[evId] = element;
        }
      });
    }
    _selectedEvents.value = events;
    setState(() {

    });
  }

  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    // Implementation example
    final days = daysInRange(start, end);

    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      if (autshUserData.role == 'su_admin' || autshUserData.role == 'admin') {
        getImportData(_getEventsForDay(selectedDay));
      } else {
        _selectedEvents.value = _getEventsForDay(selectedDay);
      }
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // `start` or `end` could be null
    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  Widget _appBarLogin() {
    if (userUid == '') {
      return Icon(Icons.verified_user, size: 0,);
    } else {
      return  Icon(Icons.verified_user, color: Colors.lightGreenAccent[700],);

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Tango Calendar',
            style: TextStyle(
                fontSize: 25,
                fontFamily: 'Frederic'
            ),
          ),

        ),
        actions: [
          Container(
            child: _appBarLogin(),
          ),
          if (statmensCount > 0)
            Text('$statmensCount',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.yellow[700]
              ),
            ),
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: _menuOpen,
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendarCuston<Event>(
            locale: kLang,
            firstDay: kFirstDay,
            lastDay: kLastDayThis,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarFormat: _calendarFormat,
            rangeSelectionMode: _rangeSelectionMode,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarBuilders: CalendarBuilders(
              // singleMarkerBuilder: SingleMarkerBuilder()
            ),
            calendarStyle: CalendarStyle(
              // Use `CalendarStyle` to customize the UI
              outsideDaysVisible: false,
              // markerDecoration: BoxDecoration(color: Colors.cyanAccent)
            ),
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              print('page change');
              updateData();
            },
          ),

          if (AllCalendars.length == 0)

            Column(
              children: [
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Calendar lIst empty',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 20
                      ),
                    ),

                    TextButton(onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);
                    },
                        child: Text('go load calendars',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 20,
                          ),
                        )
                    )
                  ],
                ),
              ],
            ),

          if (selectedCalendars.length == 0 && AllCalendars.length != 0)
            Column(
              children: [
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Calendars not selected',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 20
                      ),
                    ),

                    TextButton(onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);
                    },
                        child: Text('go select calendars',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 20,
                          ),
                        )
                    )
                  ],
                ),
              ],
            ),

          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {

                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {


                    var color = 0xFF000000;

                    if (!exportData.containsKey(value[index].eventId)
                        && AllCalendars[value[index].calendarId].typeEvents == 'festivals') {
                      if (autshUserData.role == 'su_admin' || autshUserData.role == 'admin')
                        color = 0xFFEA0707;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        onTap: () => _eventOpen(value[index]),
                        title: Column(
                          children: [
                            Row(
                              children: [
                                Text(value[index].timePeriod()),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child:
                                  Text(value[index].name, style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(color)
                                  ),),
                                ),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child:
                              Text('${value[index].locationString()}'),
                            ),

                            if (selectedCalendars.containsKey(value[index].calendarId))
                            Text("${selectedCalendars[value[index].calendarId].name}",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'calendars',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete),
            label: 'clear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.refresh),
            label: 'update',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightBlueAccent[800],
        onTap: _onItemTapped,
      ),
    );
  }


  void _onItemTapped(int index) async {

    print('_onItemTapped - $index');
    switch (index) {
      case 0:

        if (AllCalendars.length == 0) {
          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);

        } else {

          filterCalendarsDialog();
        }

        break;
      case 1:

        uploadsEventDates = {};
        await CalendarRepository().clearLocalDataJson('eventsJson');
        setState(() {
          /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
          CalEvents = {};
          kEvents = CalEvents;

          _selectedEvents.value = _getEventsForDay(_selectedDay!);
          _selectedIndex = index;
        });
        shortMessage(context, 'events deleted', 2);
        break;
      case 2:

        shortMessage(context, 'download started', 2);
        uploadsEventDates = {};
        await CalendarRepository().clearLocalDataJson('eventsJson');
        updateData();
        setState(() {
          _selectedIndex = index;
        });

        break;
    }

  }

  Future<void> updateData() async {

    if ((autshUserData.role == 'su_admin' || autshUserData.role == 'admin')) {
      usersRepository().getStatementsCount().then((value) {
        setState(() {
          statmensCount = value;
        });
      });
    }

    if (!uploadsEventDates.containsKey('minDate')) {
      uploadsEventDates['minDate'] = _focusedDay;
      uploadsEventDates['maxDate'] = _focusedDay;
      print('first start');
      uploadEvents();
    } else {
      DateTime minDate = uploadsEventDates['minDate'];
      DateTime maxDate = uploadsEventDates['maxDate'];

      if (_focusedDay.isBefore(minDate) && _focusedDay.month != minDate.month) {
        shortMessage(context, 'upload events', 2);
        uploadsEventDates['minDate'] = _focusedDay;
        print('change min date and update');
        uploadEvents();
      }
      if (_focusedDay.isAfter(maxDate) && _focusedDay.month != maxDate.month) {
        shortMessage(context, 'upload events', 2);
        uploadsEventDates['maxDate'] = _focusedDay;
        print('change max date and update');
        uploadEvents();
      }

    }

  }

  Future<void> uploadEvents() async {
    await CalendarRepository().getEventsListForMonth(_focusedDay);
    setlocaleJsonData();
    shortMessage(context, 'download complit', 2);
    print('save uploadsDates');
    Map uploadsDates = {};
    uploadsDates['minDate'] = "${uploadsEventDates['minDate']}";
    uploadsDates['maxDate'] = "${uploadsEventDates['maxDate']}";
    String data = json.encode(uploadsDates);
    localRepository().setLocalDataString('uploadsEventDates', data);
  }

  void deleteEvent() {

    ApiSigned().then((signedData) {


      var requestTokenData = {
        'tokenId': signedData['tokenId'],
        'signed': '${signedData['signed']}',
        'calId': openEvent.calendarId,
        'eventId':openEvent.eventId,
        'changeMode': changeMode
      };

      print(requestTokenData);

      CalendarRepository().apiDeleteEvent(requestTokenData).then((request) async {

        print('-------------');
        print(request);

        if (request.containsKey('errorMessage')) {
          debugPrint("error message - ${request['errorMessage']}");

          Navigator.pop(context);
          shortMessage(context, "error - ${request['errorMessage']['error']['message']}", 2);
        } else {

          Navigator.pop(context);
          _onItemTapped(2);

          Navigator.pop(context);
          shortMessage(context, 'delete complit', 2);

        }

      });

    });
  }

  void _onEventOpenItemTapped(int index) async {
    switch (index) {
      case 0:
        if ((autshUserData.role == 'su_admin' || autshUserData.role == 'admin')) {
          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(context, '/event_settings', (route) => false);
        }
        break;
      case 1:

        if(autshUserData.role != null && ((userCalendarsPermissions.containsKey(key)
            && userCalendarsPermissions[openEvent.calendarId]['delete'] > 0
            && CalendarPermEventDelete[autshUserData.role] > 1)
            || selectedCalendars[openEvent.calendarId].creator == autshUserData.uid
            || CalendarPermEventDelete[autshUserData.role] > 1)) {

          deleteEventDialog();

        } else {
          shortMessage(context, 'delete not permission', 2);
        }

        break;
      case 2:
        if(autshUserData.role != null && ((userCalendarsPermissions.containsKey(key)
            && userCalendarsPermissions[openEvent.calendarId]['redact'] > 0
            && CalendarPermEventDelete[autshUserData.role] > 1)
            || selectedCalendars[openEvent.calendarId].creator == autshUserData.uid
            || CalendarPermEventDelete[autshUserData.role] > 1)) {

          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(context, '/edit_event', (route) => false);

        } else {
          shortMessage(context, 'edit not permission', 2);
        }

        break;
    }

  }

}
