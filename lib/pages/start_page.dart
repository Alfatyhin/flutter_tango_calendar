import 'dart:collection';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../firebase_options.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:new_version_plus/new_version_plus.dart';


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

  bool auth = false;
  var CalEvents = {};
  Map eventsPermissions = {};
  var userUid = '';
  var userRole = '';
  var key = DateTime.now();
  int _selectedIndex = 0;
  int _selectedIndexEventOpen = 0;
  int statmensCount = 0;
  DateTime kLastDayThis = kLastDay;
  bool shouldPop = false;
  int priodUpdate = 30;
  double rowHeight = 26;
  double fontsize = 16;
  Map<double, double> fontSizes = {
    26: 16,
    28: 16.5,
    30: 17,
    32: 17.5,
    34: 18,
    36: 18.5,
    38: 19,
    40: 20,
    42: 20.5,
    44: 21,
    46: 21.5
  };


  List shortFilter = [];

  Map uploadsEventDates = {};

  Map exportData = {};
  List exportIds = [];

  @override
  void initState() {
    super.initState();
    initFirebase();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    print('init state');

    if (backCommand['comand'] == 'refresh') {
      backCommand['comand'] = '';
      refreshCommand();
    }

    if (!newVersionShow) {
      newVersionShow = true;
      newVersionMain.showAlertIfNecessary(context: context);
    }

  }

  void initFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).whenComplete(() {
      print('init completed');
      initCalendars();
    });
    
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) async {
      if (user != null) {

        UserData userData = await usersRepository().getUserDataByUid(user.uid!);
        if (emulateUser) {
           userData = await usersRepository().getUserDataByUid(emulateUserId);
        }

        autshUserData = userData;
        auth = true;
        if (autshUserData.role == 'su_admin' || autshUserData.role == 'admin') {
          pro = true;
          calendarsMapped();
          usersRepository().getStatementsCount().then((value) {
            statmensCount = value;
            setState(() {
              statmensCount = value;
            });
          });
        }

        if (autshUserData.role == 'su_admin' || autshUserData.role == 'admin') {

        } else {
          eventsPermissions = await usersRepository().getUserEventsPermissions(autshUserData.uid);

        }

        CalendarRepository().getUserCalendarsPermissions(autshUserData.uid).then((value) {
          userCalendarsPermissions = value;
        });

        if (userData.role == 'admin'
            || userData.role == 'su_admin'
            || userData.role == 'organizer'
            || pro == true) {
          kLastDayThis = DateTime(kToday.year, kToday.month + 18, kToday.day);
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


  void initCalendars(){

    calendarsMapped();
    kEvents = CalEvents;
    //////////////////////////////////
    localRepository().getLocalDataString('shortFilter').then((value){
      if (value != '') {
        setState(() {
          shortFilter = json.decode(value as String);
        });
      }
    });

    localRepository().getLocalDataDouble('rowHeight').then((value){
      print('rowHeight - ${value}');
      if (value != 0) {
        setState(() {
          rowHeight = value!;
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

    localRepository().getLocalDataString('priodUpdate').then((value){
      print('priodUpdate - ${value}');
      if (value != '') {
        priodUpdate = value as int;
      }
      localRepository().getLocalDataString('lastUpdateEventsData').then((value){
        print('lastUpdateEventsData - ${value}');

        DateTime dateNow = DateTime.now();
        if (value != '') {
          print('lastUpdateEventsData - not empty');
          DateTime lastUpdateEventsData = DateTime.parse(value!);
          DateTime endpoint = lastUpdateEventsData.add(Duration(minutes: priodUpdate));

          if (dateNow.isAfter(endpoint)) {
            shortMessage(context, 'auto update events', 2);
            _onItemTapped(2);
            localRepository().setLocalDataString('lastUpdateEventsData', dateNow.toString());
          }

        } else {
          _onItemTapped(2);
          localRepository().setLocalDataString('lastUpdateEventsData', dateNow.toString());
        }
      });

    });

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

                  print('calendar.typeEvents');
                  print(calendar.typeEvents);

                  if (calendar.typeEvents == 'festivals') {
                    calendar.setColorHash('0xFFA90000');
                  }
                  if (calendar.typeEvents == 'milongas') {
                    calendar.setColorHash('0xFF06A900');
                  }
                  if (calendar.typeEvents == 'master_classes') {
                    calendar.setColorHash('0xFFA97900');
                  }
                  if (calendar.typeEvents == 'tango_school') {
                    calendar.setColorHash('0xFF003BA9');
                  }

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




  Future<void> refreshCommand() async {
    uploadsEventDates = {};
    await CalendarRepository().clearLocalDataJson('eventsJson');
    updateData();
  }


  void _menuOpen() {


    var title = AppLocalizations.of(context)!.menu;
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {

          if (userUid == '') {

            return Scaffold(
              appBar: AppBar(title: Text(title),),
              body:
              Container(
                margin: EdgeInsets.all(30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    ElevatedButton(onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(context, '/register_user', (route) => false);
                    }, child: Text(AppLocalizations.of(context)!.register,
                      style: TextStyle(
                          fontSize: 20
                      ),),),


                    ElevatedButton(onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(context, '/login_user', (route) => false);
                    }, child: Text(AppLocalizations.of(context)!.login,
                      style: TextStyle(
                          fontSize: 20
                      ),),),


                    const SizedBox(height: 5),
                    ElevatedButton(onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(context, '/about', (route) => false);
                    }, child: Text("${AppLocalizations.of(context)!.about}    v - $v",
                      style: TextStyle(
                          fontSize: 20
                      ),),),
                  ],
                ),
              ),
            );

          } else {

            return Scaffold(
              appBar: AppBar(title: Text(title),),
              body:
              Container(
                margin: EdgeInsets.all(30.0),
                child:  Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(context, '/fb_events', (route) => false);
                    }, child: Text(AppLocalizations.of(context)!.facebookEvents,
                      style: TextStyle(
                          fontSize: 20
                      ),),),

                    ElevatedButton(onPressed: () {
                      _logOut();
                      Navigator.pop(context);
                    }, child: Text(AppLocalizations.of(context)!.logOut,
                      style: TextStyle(
                          fontSize: 20
                      ),),),


                    ElevatedButton(onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(context, '/user_profile', (route) => false, arguments: userUid);
                    }, child: Text(AppLocalizations.of(context)!.myProfile,
                      style: TextStyle(
                          fontSize: 20
                      ),),),




                    if (autshUserData.role == 'su_admin')

                      ElevatedButton(onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(context, '/users', (route) => false);
                      }, child: Text(AppLocalizations.of(context)!.users,
                        style: TextStyle(
                            fontSize: 20
                        ),),),

                    if (autshUserData.role == 'su_admin')
                      ElevatedButton(onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(context, '/statements', (route) => false);
                      }, child: Text(AppLocalizations.of(context)!.statements,
                        style: TextStyle(
                            fontSize: 20
                        ),),),


                    if (autshUserData.role != 'user')

                      ElevatedButton(onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(context, '/add_calendar', (route) => false);
                      }, child: Text(AppLocalizations.of(context)!.addCalendar,
                        style: TextStyle(
                            fontSize: 20
                        ),),),


                    if (autshUserData.role == 'su_admin'
                        || autshUserData.role == 'admin'
                        || autshUserData.role == 'organizer')

                      ElevatedButton(onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(context, '/create_event', (route) => false);
                      }, child: Text(AppLocalizations.of(context)!.createEvent,
                        style: TextStyle(
                            fontSize: 20
                        ),),),


                    ElevatedButton(onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);
                    }, child: Text(AppLocalizations.of(context)!.calendars,
                      style: TextStyle(
                          fontSize: 20
                      ),),),


                    ElevatedButton(onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(context, '/about', (route) => false);
                    }, child: Text("${AppLocalizations.of(context)!.about}    v - $v",
                      style: TextStyle(
                          fontSize: 20
                      ),),),
                  ],
                ),
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

  Future<void> _eventOpen(Event event) async {
    _changeMode = EventChangeMode.one;
    changeMode = "one";
    openEvent = event;
    var eventGuid = getEventGUid(event.eventId);
    print('eventId - ${event.eventId}');

    // final html = await fetchHtml(event.url);
    // Clipboard.setData(ClipboardData(text: html));

    // final imageUrl = extractImageUrl(html);
    // print('Main Event Image URL: $imageUrl');
    // print(event.url);

    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context)!.eventData),),
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

                  if (autshUserData.role == 'su_admin' || autshUserData.role == 'admin')
                    ElevatedButton(
                      onPressed: () {
                        Uri url = Uri.parse("http://maps.google.com/maps?q=${event.locationString()}");
                        _launchUrl(url);
                      },
                      child: Text('go map'),
                    ),


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

                  if (event.url != '')
                    ElevatedButton(
                    onPressed: () {
                      Uri url = Uri.parse(event.url);
                      _launchUrl(url);
                    },
                    child: Text('go event'),
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
                    label: AppLocalizations.of(context)!.import,
                  )
                else
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings, color: Colors.grey[300],),
                    label: AppLocalizations.of(context)!.import,
                  ),



                if(autshUserData.role != null && ((userCalendarsPermissions.containsKey(key)
                    && userCalendarsPermissions[event.calendarId]['delete'] > 0
                    && CalendarPermEventDelete[autshUserData.role] > 1)
                    || selectedCalendars[event.calendarId].creator == autshUserData.uid
                    || CalendarPermEventDelete[autshUserData.role] > 1)
                    || (eventsPermissions.containsKey(eventGuid) && eventsPermissions[eventGuid]['delete'] > 0))

                  BottomNavigationBarItem(
                    icon: Icon(Icons.delete, color: Colors.green,),
                    label: AppLocalizations.of(context)!.delete,
                  )
                else if (userCalendarsPermissions.containsKey(event.calendarId)
                    && userCalendarsPermissions[event.calendarId]['delete'] > 0
                    && CalendarPermEventDelete[autshUserData.role] == 1)

                  BottomNavigationBarItem(
                    icon: Icon(Icons.delete, color: Colors.blue,),
                    label: AppLocalizations.of(context)!.delete,
                  )

                else

                  BottomNavigationBarItem(
                    icon: Icon(Icons.delete, color: Colors.grey[300],),
                    label: AppLocalizations.of(context)!.delete,
                  ),


                if(autshUserData.role != null && ((userCalendarsPermissions.containsKey(key)
                    && userCalendarsPermissions[event.calendarId]['redact'] > 0
                    && CalendarPermEventRedact[autshUserData.role] > 1)
                    || selectedCalendars[event.calendarId].creator == autshUserData.uid
                    || CalendarPermEventDelete[autshUserData.role] > 1)
                    || (eventsPermissions.containsKey(eventGuid) && eventsPermissions[eventGuid]['redact'] > 0))

                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long, color: Colors.green,),
                    label: AppLocalizations.of(context)!.edit,
                  )

                else if((userCalendarsPermissions.containsKey(key)
                    && userCalendarsPermissions[event.calendarId]['redact'] > 0
                    && CalendarPermEventRedact[autshUserData.role] > 1))

                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long, color: Colors.blue,),
                    label: AppLocalizations.of(context)!.edit,
                  )

                else
                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long, color: Colors.grey[300],),
                    label: AppLocalizations.of(context)!.edit,
                  ),

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
          shrinkWrap: true,
          children: [
            Center(
              child: Text(AppLocalizations.of(context)!.activeCalendars,
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue
                ),
              ),
            ),
            Column(
              children: List<Widget>.generate(
                  dialogList.length,
                      (int index) {
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
                  }
              ),
            ),

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
                        child: Text(AppLocalizations.of(context)!.calendarS)
                    ),

                    ElevatedButton(
                        onPressed: ()  {
                          Navigator.of(context).pop();
                          setlocaleJsonData();
                        },
                        child: Text("Ok"))

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

                        Text(AppLocalizations.of(context)!.onlyThis),

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

                        Text(AppLocalizations.of(context)!.thisAfter),

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

                        Text(AppLocalizations.of(context)!.all),

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
                          child: Text(AppLocalizations.of(context)!.delete)),

                      ElevatedButton(
                          onPressed: ()  {
                            Navigator.of(context).pop();
                            setlocaleJsonData();
                          },
                          child: Text(AppLocalizations.of(context)!.close))

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

             element['colorHash'] = AllCalendars[element['calId']].colorHash;

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

  SureExitDialog(BuildContext context) {
    Widget cancelButton = TextButton(
      child: Text(AppLocalizations.of(context)!.stay),
      onPressed:  () {Navigator.pop(context);},
    );
    Widget yesButton = TextButton(
      child: Text(AppLocalizations.of(context)!.yes),
      onPressed:  () {
        shouldPop = true;
        Navigator.pop(context);
      },
    );
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.confirmatioN),
      content: Text(AppLocalizations.of(context)!.confirmExitText),
      actions: [
        cancelButton,
        yesButton,
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    double iconHeight = 42;

    return WillPopScope(
      onWillPop: () async {
        if (shouldPop == false ) {
          SureExitDialog(context);
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(AppLocalizations.of(context)!.tangoCalendar,
              style: TextStyle(
                  fontSize: 20,
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
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Column(
                 children: [
                   Container(
                     width: 270,
                     child: TableCalendarCuston<Event>(
                       locale: Localizations.localeOf(context).toString(),
                       firstDay: kFirstDay,
                       lastDay: kLastDayThis,
                       rowHeight: rowHeight,
                       focusedDay: _focusedDay,
                       selectedDayPredicate: (day) {
                         // Use `selectedDayPredicate` to determine which day is currently selected.
                         // If this returns true, then `day` will be marked as selected.

                         // Using `isSameDay` is recommended to disregard
                         // the time-part of compared DateTime objects.
                         return isSameDay(_selectedDay, day);
                       },
                       rangeStartDay: _rangeStart,
                       rangeEndDay: _rangeEnd,
                       calendarFormat: _calendarFormat,
                       rangeSelectionMode: _rangeSelectionMode,
                       eventLoader: _getEventsForDay,
                       startingDayOfWeek: StartingDayOfWeek.monday,
                       calendarBuilders: CalendarBuilders(
                         // singleMarkerBuilder: SingleMarkerBuilder()
                       ),
                       headerStyle: HeaderStyle(
                         titleTextStyle: const TextStyle(fontSize: 12.0),
                       ),
                       calendarStyle: CalendarStyle(
                         todayTextStyle: TextStyle(
                           fontSize: fontSizes[rowHeight]
                         ),
                         defaultTextStyle: TextStyle(
                           fontSize: fontSizes[rowHeight]
                         ),
                         selectedTextStyle: TextStyle(
                             color: const Color(0xFFFAFAFA),
                             fontSize: fontSizes[rowHeight]
                         ),
                         weekendTextStyle: TextStyle(
                           fontSize: fontSizes[rowHeight]
                         ),
                         // Use `CalendarStyle` to customize the UI
                         outsideDaysVisible: false,
                         cellMargin: EdgeInsets.all(3.0),
                         markersMaxCount: 4,
                         markerSize: 6,
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
                   ),
                 ],
               ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 mainAxisSize: MainAxisSize.max,
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [

                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Container (
                         width: 32,
                         height: iconHeight,
                         child: IconButton(
                           padding: EdgeInsets.all(1),
                           style: ButtonStyle(
                             padding: MaterialStateProperty.all<EdgeInsets>(
                                 EdgeInsets.all(1)),
                           ),
                           onPressed: (){
                             if (rowHeight > 26 ) {
                               rowHeight = rowHeight - 2;
                               localRepository().setLocalDataDouble('rowHeight', rowHeight);
                               setState(() {

                               });
                             }
                           },
                           icon: Icon(Icons.horizontal_rule, color: Colors.lightBlue,),
                         ),
                       ),
                       Container (
                         width: 10,
                         height: iconHeight,
                       ),
                       Container (
                         width: 32,
                         height: iconHeight,
                         child: IconButton(
                           padding: EdgeInsets.all(1),
                           style: ButtonStyle(
                             padding: MaterialStateProperty.all<EdgeInsets>(
                                 EdgeInsets.all(1)),
                           ),
                           onPressed: (){
                             _onItemTapped(0);
                           },
                           icon: Icon(Icons.list_alt, color: Colors.lightBlue,),
                         ),
                       ),
                     ],
                   ),

                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Container (
                         width: 32,
                         height: iconHeight,
                         child: IconButton(
                           padding: EdgeInsets.all(1),
                           style: ButtonStyle(
                             padding: MaterialStateProperty.all<EdgeInsets>(
                                 EdgeInsets.all(0.5)),
                           ),
                           onPressed: (){
                             if (rowHeight < 46 ) {
                               rowHeight = rowHeight + 2;
                               localRepository().setLocalDataDouble('rowHeight', rowHeight);
                               setState(() {

                               });
                             }
                           },
                           icon: Icon(Icons.add, color: Colors.lightBlue,),
                         ),
                       ),
                       Container (
                         width: 10,
                         height: iconHeight,
                       ),
                       Container (
                         width: 32,
                         height: iconHeight,
                         child: IconButton(
                           padding: EdgeInsets.all(1),
                           style: ButtonStyle(
                             padding: MaterialStateProperty.all<EdgeInsets>(
                                 EdgeInsets.all(0.5)),
                           ),
                           onPressed: (){
                             _onItemTapped(1);
                           },
                           icon: Icon(Icons.delete, color: Colors.grey,),
                         ),
                       ),
                     ],
                   ),

                   Container (
                     width: 32,
                     height: iconHeight,
                     child: IconButton(
                       padding: EdgeInsets.all(1),
                       style: ButtonStyle(
                         padding: MaterialStateProperty.all<EdgeInsets>(
                             EdgeInsets.all(0.5)),
                       ),
                       onPressed: (){
                         _onItemTapped(2);
                       },
                       icon: Icon(Icons.refresh, color: Colors.green,),
                     ),
                   ),


                   if (auth && (autshUserData.role == 'su_admin'
                       || autshUserData.role == 'admin'
                       || autshUserData.role == 'organizer'))

                     Container (
                       width: 32,
                       height: iconHeight,
                       child: IconButton(
                         padding: EdgeInsets.all(1),
                         style: ButtonStyle(
                           padding: MaterialStateProperty.all<EdgeInsets>(
                               EdgeInsets.all(1)),
                         ),
                         onPressed: (){
                           Navigator.pop(context);
                           Navigator.pushNamedAndRemoveUntil(context, '/create_event', (route) => false);

                         },
                         icon: Icon(Icons.add, color: Colors.green,),
                       ),
                     ),


                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       if (emulateUser)
                        Container (
                         width: 32,
                         height: iconHeight,
                         child: IconButton(
                           padding: EdgeInsets.all(1),
                           style: ButtonStyle(
                             padding: MaterialStateProperty.all<EdgeInsets>(
                                 EdgeInsets.all(1)),
                           ),
                           onPressed: (){
                             emulateUser = false;
                             emulateUserId = '';
                             setState(() {
                               initFirebase();
                             });
                           },
                           icon: Icon(Icons.outbond_rounded, color: Colors.green[600],),
                         ),
                       ),
                       Container (
                         width: 10,
                         height: iconHeight,
                       ),

                       Container (
                         width: 35,
                         height: iconHeight,
                         child:
                         TextButton(
                             onPressed:  (){
                               Navigator.pop(context);
                               Navigator.pushNamedAndRemoveUntil(context, '/fb_events', (route) => false);

                             },
                             child: Text('Fb',
                               style: TextStyle(
                                 fontWeight: FontWeight.w900,
                                 color: Colors.blueAccent,
                               ),
                             )),
                       ),
                     ],
                   ),




                 ],
               ),
             ],
           ),


            if (AllCalendars.length == 0)

              Column(
                children: [
                  const SizedBox(height: 3.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context)!.calendarListEmpty,
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 20
                        ),
                      ),

                      TextButton(onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);
                      },
                          child: Text(AppLocalizations.of(context)!.loadCalendars,
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
                  const SizedBox(height: 3.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context)!.calendarsNotSelected,
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 20
                        ),
                      ),

                      TextButton(onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);
                      },
                          child: Text(AppLocalizations.of(context)!.selectedCalendars,
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

            const SizedBox(height: 3.0),
            Expanded(
              child: ValueListenableBuilder<List<Event>>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {

                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {

                      String colorHash = value[index].colorHash;
                      String calNameColor = '0xFF0099FA';
                      if (autshUserData.role == 'su_admin') {
                        calNameColor = colorHash;
                      }


                      var color = 0xFF000000;

                      if (!exportData.containsKey(value[index].eventId)
                          && AllCalendars[value[index].calendarId].typeEvents == 'festivals') {
                        if (auth && (autshUserData.role == 'su_admin' || autshUserData.role == 'admin'))
                          color = 0xFFEA0707;
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(int.parse(colorHash)),
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          onTap: () => _eventOpen(value[index]),
                          title: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(value[index].timePeriod()),
                                  // Container(
                                  //   // color: Colors.cyanAccent[200],
                                  //   width: 20,
                                  //   height: 20,
                                  //   decoration: ShapeDecoration(
                                  //     color: Color(int.parse(colorHash)), shape: CircleBorder(),
                                  //   ),
                                  // )
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
                                      color: Color(int.parse(calNameColor)),
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
        shortMessage(context, AppLocalizations.of(context)!.storageCleared, 2);
        break;
      case 2:

        shortMessage(context, AppLocalizations.of(context)!.downloadStarted, 2);
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

    if (auth && (autshUserData.role == 'su_admin' || autshUserData.role == 'admin')) {
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
        shortMessage(context, AppLocalizations.of(context)!.uploadEvents, 2);
        uploadsEventDates['minDate'] = _focusedDay;
        print('change min date and update');
        uploadEvents();
      }
      if (_focusedDay.isAfter(maxDate) && _focusedDay.month != maxDate.month) {
        shortMessage(context, AppLocalizations.of(context)!.uploadEvents, 2);
        uploadsEventDates['maxDate'] = _focusedDay;
        print('change max date and update');
        uploadEvents();
      }

    }

  }

  Future<void> uploadEvents() async {

    await CalendarRepository().getEventsListForMonth(_focusedDay).then((value)  {
      if (value.containsKey('error')) {
        shortMessage(context, value['error'], 2);
      } else {
        setlocaleJsonData();
        shortMessage(context, AppLocalizations.of(context)!.downloadComplit, 2);
        print('save uploadsDates');
        Map uploadsDates = {};
        uploadsDates['minDate'] = "${uploadsEventDates['minDate']}";
        uploadsDates['maxDate'] = "${uploadsEventDates['maxDate']}";
        String data = json.encode(uploadsDates);
        localRepository().setLocalDataString('uploadsEventDates', data);
      }
    });

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

          usersRepository().deleteUserEventsPermissions(getEventGUid(openEvent.eventId));

          Navigator.pop(context);
          _onItemTapped(2);

          Navigator.pop(context);
          shortMessage(context, AppLocalizations.of(context)!.deleteComplit, 2);

        }

      });

    });
  }

  void _onEventOpenItemTapped(int index) async {

    var eventGUid = getEventGUid(openEvent.eventId);

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
            || CalendarPermEventDelete[autshUserData.role] > 1)
            || eventsPermissions[eventGUid]['delete'] > 0) {

          deleteEventDialog();

        } else {
          shortMessage(context, AppLocalizations.of(context)!.deleteNotPermission, 2);
        }

        break;
      case 2:
        if(autshUserData.role != null && ((userCalendarsPermissions.containsKey(key)
            && userCalendarsPermissions[openEvent.calendarId]['redact'] > 0
            && CalendarPermEventDelete[autshUserData.role] > 1)
            || selectedCalendars[openEvent.calendarId].creator == autshUserData.uid
            || CalendarPermEventDelete[autshUserData.role] > 1)
            || eventsPermissions[eventGUid]['redact'] > 0) {

          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(context, '/edit_event', (route) => false);

        } else {
          shortMessage(context, AppLocalizations.of(context)!.editNotPermission, 2);
        }

        break;
    }

  }


  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }
}
