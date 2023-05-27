import 'dart:collection';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tango_calendar/repositories/users/users_reposirory.dart';


import '../AppTools.dart';
import '../models/Calendar.dart';
import '../models/table_calendar.dart';
import '../models/Event.dart';
import '../models/UserData.dart';
import '../repositories/calendar/calendar_repository.dart';
import '../utils.dart';

late final FirebaseApp app;
late final FirebaseAuth auth;



class StartPage extends StatefulWidget {
  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {

  var userUid = '';
  var userRole = '';
  var key = DateTime.now();
  var value = Event('1', 'test event', 'нет событий', 'test event', 0, 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'start page');
  int _selectedIndex = 0;
  int _selectedIndexEventOpen = 0;
  int statmensCount = 0;



  void initFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp().whenComplete(() {
      print('init completed');
      ///  загрузка событий из локального хранилища
      setlocaleJsonData();
    });
    
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) async {
      if (user != null) {
        UserData userData = await usersRepository().getUserDataByUid(user.uid!);

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

        setState(() {
          userRole = userData.role;
          userUid = user.uid!;
        });
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

  @override
  void initState() {
    super.initState();
    initFirebase();
    print('int state');
    ///  без событий календарь валится
    kEventSource = {this.key: [value]};
    /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
    kEvents = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(kEventSource);
    //////////////////////////////////


    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));



    CalendarRepository().getLocalDataJson('selectedCalendars').then((selectedCalendarsJson) {

      CalendarRepository().getLocalDataJson('calendars').then((calendarsJson) {

        var selectedData = [];
        if (selectedCalendarsJson != '') {
          selectedData = json.decode(selectedCalendarsJson as String);
        }
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

      });

    });

  }

  void _menuOpen() {

    var title = 'Меню';
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

    openEvent = event;

    print(event.calendarId);
    print(event.eventId);
    print(selectedCalendars[event.calendarId]?.gcalendarId);


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

                if((userCalendarsPermissions.containsKey(key)
                    && userCalendarsPermissions[event.calendarId]['delete'] > 0
                    && CalendarPermEventDelete[autshUserData.role] > 1)
                    || selectedCalendars[event.calendarId].creator == autshUserData.uid
                    || CalendarPermEventDelete[autshUserData.role] > 1)

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

                if((userCalendarsPermissions.containsKey(key)
                    && userCalendarsPermissions[event.calendarId]['redact'] > 0
                    && CalendarPermEventRedact[autshUserData.role] > 1)
                    || selectedCalendars[event.calendarId].creator == autshUserData.uid
                    || CalendarPermEventDelete[autshUserData.role] > 1)

                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long, color: Colors.green,),
                    label: 'redact',
                  )

                else if((userCalendarsPermissions.containsKey(key)
                    && userCalendarsPermissions[event.calendarId]['redact'] > 0
                    && CalendarPermEventRedact[autshUserData.role] > 1)
                    || CalendarPermEventRedact[autshUserData.role] == 1)

                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long, color: Colors.blue,),
                    label: 'redact',
                  )

                else
                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long, color: Colors.grey,),
                    label: 'redact',
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


  @override
  Future<void> setlocaleJsonData() async {
    CalendarRepository()
        .getLocalDataJson('eventsJson')
        .then((oldJson) {

      if (oldJson != '') {
        var data = json.decode(oldJson as String);
        kEventSource = CalendarRepository().getKeventToDataMap(data) as Map<DateTime, List<Event>>;

        /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
        kEvents = LinkedHashMap<DateTime, List<Event>>(
          equals: isSameDay,
          hashCode: getHashCode,
        )..addAll(kEventSource);
        setState(() {});
        _selectedEvents.value = _getEventsForDay(_selectedDay!);

      }
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {

    // Implementation example
    return kEvents[day] ?? [];
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

      _selectedEvents.value = _getEventsForDay(selectedDay);
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
          child: Text('Tango Calendar'),
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
            lastDay: kLastDay,
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
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
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
                                      fontWeight: FontWeight.w600
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
    switch (index) {
      case 0:
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);
        break;
      case 1:
        await CalendarRepository().clearLocalDataJson('eventsJson');
        setState(() {
          kEventSource = {this.key: [value]};
          /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
          kEvents = LinkedHashMap<DateTime, List<Event>>(
            equals: isSameDay,
            hashCode: getHashCode,
          )..addAll(kEventSource);

          _selectedEvents.value = _getEventsForDay(_selectedDay!);
          _selectedIndex = index;
        });
        shortMessage(context, 'events deleted', 2);
        break;
      case 2:
        if (autshUserData.role == 'su_admin' || autshUserData.role == 'admin') {
          usersRepository().getStatementsCount().then((value) {
            setState(() {
              statmensCount = value;
            });
          });
        }
        shortMessage(context, 'upload events', 2);
        kEvents = await CalendarRepository().getEventsList();
        setState(() {
          _selectedIndex = index;
        });
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
        shortMessage(context, 'upload complit', 2);
        break;
    }

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

        if((userCalendarsPermissions.containsKey(key)
            && userCalendarsPermissions[openEvent.calendarId]['delete'] > 0
            && CalendarPermEventDelete[autshUserData.role] > 1)
            || selectedCalendars[openEvent.calendarId].creator == autshUserData.uid
            || CalendarPermEventDelete[autshUserData.role] > 1) {
          print('delete permission true');

          ApiSigned().then((signedData) {


            var requestTokenData = {
              'tokenId': signedData['tokenId'],
              'signed': '${signedData['signed']}',
              'calId': openEvent.calendarId,
              'eventId':openEvent.eventId
            };

            Navigator.pop(context);

            CalendarRepository().apiDeleteEvent(requestTokenData).then((value) async {

              CalendarRepository().importDeleteEvent(openEvent.calendarId, openEvent.eventId);
              CalendarRepository().getEventsList().then((value) {
                setState(() {
                  kEvents = value;
                });
                _selectedEvents.value = _getEventsForDay(_selectedDay!);
              });
              shortMessage(context, 'delete complit', 2);

            });

          });

        } else {
          shortMessage(context, 'delete not permission', 2);
        }

        break;
      case 2:

        shortMessage(context, 'upload complit', 2);
        break;
    }

  }

}
