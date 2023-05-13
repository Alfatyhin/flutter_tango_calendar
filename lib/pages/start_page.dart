import 'dart:collection';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tango_calendar/repositories/users/users_reposirory.dart';


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
  var value = Event('1', 'test event', 'нет событий', 'test event', 0, 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'test event');
  var kEvents;
  int _selectedIndex = 0;


  void initFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp().whenComplete(() => print('completed'));
    
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) async {
      if (user != null) {
        UserData userData = await usersRepository().getUserDataByUid(user.uid!);

        setState(() {
          userRole = userData.role;
          userUid = user.uid!;
          print(user.displayName);
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

    ///  загрузка событий из локального хранилища
    setlocaleJsonData();

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));

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
            if (userRole == 'su_admin') {
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
                      Navigator.pushNamedAndRemoveUntil(context, '/users', (route) => false);
                    }, child: Text('Users',
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
                  ],
                ),
              );
            }

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
            )
          );
        })
    );
  }


  @override
  Future<void> setlocaleJsonData() async {
    // CalendarRepository().setLocalDataJson('test', 'test 1');

    var oldJson = await CalendarRepository().getLocalDataJson('eventsJson');
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
      return Icon(Icons.verified_user, color: Colors.grey,);
    } else {
      return Icon(Icons.verified_user, color: Colors.lightGreenAccent[700],);
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
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        onTap: () => _eventOpen(value[index]),
                        title: Row(
                          textDirection: TextDirection.ltr,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(value[index].name, style: TextStyle(
                                  fontWeight: FontWeight.w600
                                ),),
                                Text(value[index].timePeriod()),
                              ],
                            )
                          ],
                        ),
                        subtitle: Text('${value[index].locationString()}'),
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
        _shortMessage('events deleted', 2);
        break;
      case 2:
        _shortMessage('upload events', 2);
        kEvents = await CalendarRepository().getEventsList();
        setState(() {
          _selectedIndex = index;
        });
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
        _shortMessage('upload complit', 2);
        break;
    }

  }

  void _shortMessage(String text, int sec) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Center(
        child: Text(text),
      ),
      backgroundColor: Colors.blueAccent,
      duration: Duration(seconds: sec),
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.symmetric(
        horizontal: 8.0, // Inner padding for SnackBar content.
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    ));
  }
}
