import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tango_calendar/AppTools.dart';
import 'package:tango_calendar/models/FbEvent.dart';
import 'package:tango_calendar/models/Calendar.dart';
import 'package:tango_calendar/repositories/calendar/fb_events_repository.dart';

import 'package:tango_calendar/icalendar_parser.dart';
import '../repositories/calendar/calendar_repository.dart';
import '../utils.dart';

class FbEvents extends StatefulWidget {
  const FbEvents({Key? key}) : super(key: key);

  @override
  _FbEventsState createState() => _FbEventsState();
}

class _FbEventsState extends State<FbEvents> {

  List<FbEvent> Events = [];
  late ICalendar _iCalendar;
  String eventsUrl = '';
  int _selectedIndex = 0;
  bool _isLoading = false;
  List selectedCalendars = [];
  Map eventImportMap = {};
  List calendarImportList = [];
  late FbEvent activeEvent;

  var icon = Icon(Icons.add);

  @override
  void initState() {
    super.initState();
    getEvents();
  }

  BottomNavigationBarItem _calendarButton() {
    if (eventsUrl == '') {
      return BottomNavigationBarItem(
        icon: Icon(Icons.add),
        label: 'add url',
      );
    } else {
      return BottomNavigationBarItem(
        icon: Icon(Icons.refresh),
        label: 'update',
      );
    }
  }

  Future<void> getEvents() async {
    _isLoading = true;
    selectedCalendars = [];
    eventImportMap = {};

    List fbEventsIdsList = [];

    FbEventsRepository().getLocalDataString('eventsUrl').then((value){
      eventsUrl = value!;

      if (eventsUrl != '') {
        FbEventsRepository().getLocalDataString('fbEvents').then((value){
          String fbCalendar = value as String;

          if (fbCalendar != '') {
            final now = DateTime.now().toLocal();
            final iCalendar = ICalendar.fromString(fbCalendar);
            Events = [];

            iCalendar.data.forEach((element) {


              var dateTimeStart = DateTime.parse(element['dtstart'].dt).add(Duration(hours: 3));
              var dateStart = DateFormatDate(dateTimeStart);
              var timeStart = DateFormatTime(dateTimeStart);

              var dateTimeEnd = DateTime.parse(element['dtend'].dt).add(Duration(hours: 3));
              var dateEnd = DateFormatDate(dateTimeEnd);
              var timeEnd = DateFormatTime(dateTimeEnd);

              var date = DateTime.parse(element['lastModified'].dt).add(Duration(hours: 3));
              var modifedDate = DateFormatDate(date);
              var modifedtime = DateFormatTime(date);

              var cEvent = FbEvent(
                  element['uid'],
                  element['summary'],
                  element['description'],
                  element['location'],
                  1,
                  dateStart,
                  timeStart,
                  dateEnd,
                  timeEnd,
                  '$modifedDate $modifedtime',
                  element['organizer']['mail'],
                  element['organizer']['name'],
                  element['organizer']['mail'],
                  element['organizer']['name'],
                  'facebook'
              );
              cEvent.url = element['url'];
              cEvent.importData = element;

              if (now.isBefore(dateTimeEnd)) {
                Events.add(cEvent);
                fbEventsIdsList.add(cEvent.eventId);
              }
              if (Events.length == 1) {
                activeEvent = cEvent;
              }

            });

            Events.sort(
                    (a, b) {
                  int testa = -1;

                  var adate = DateTime.parse(a.dateStart);
                  var bdate = DateTime.parse(b.dateStart);
                  if (adate.isAfter(bdate)) {
                    testa = 1;
                  }
                  if (adate.isAtSameMomentAs(bdate)) {
                    testa = 0;
                  }
                  return testa;
                }
            );


            print("fbEventsIdsList size start - ${fbEventsIdsList.length}");

            while(fbEventsIdsList.length > 0 ) {
              int size = 10;
              if (fbEventsIdsList.length < 10) {
                size = fbEventsIdsList.length;
              }
              List list = fbEventsIdsList.sublist(0, size);

              fbEventsIdsList.removeRange(0, size);

              CalendarRepository().getImportEventDataIds(list as List).then((value) {
                value.forEach((element) {

                  print(element);
                  if (eventImportMap.containsKey(element['eventExportId'])) {
                    eventImportMap[element['eventExportId']].add(element);
                  } else {
                    eventImportMap[element['eventExportId']] = [element];
                  }
                });

                setState(() {});
              });
            }


            setState(() {
              eventsUrl = eventsUrl;
              Events = Events;
              _iCalendar = iCalendar;
              _isLoading = false;
            });
          }

        });
      }

    });


    ////
    var calendarsJson = await CalendarRepository().getLocalDataJson('calendars');
    var selectedCalendarsJson = await CalendarRepository().getLocalDataJson('selectedCalendars');


    var selectedData = [];

    if (selectedCalendarsJson != '') {
      selectedData = json.decode(selectedCalendarsJson as String);
    }
    if (selectedData.length > 0) {

    } else {
      print('not selected');
    }

    if (calendarsJson != '') {
      List data = json.decode(calendarsJson as String);

      List calendarsData = data;

        if (autshUserData.role == 'admin' || autshUserData.role == 'su_admin') {
          calendarsData.forEach((value) {
            var calendar = Calendar.fromLocalData(value);
            if (selectedData.contains(calendar.id)) {
              calendar.enable = false;
              selectedCalendars.add(calendar);
            }
          });

        } else {
          if (autshUserData.role != 'user' ) {
            CalendarRepository().getUserCalendarsPermissions(autshUserData.uid).then((UserCalendarsPermission) {

              calendarsData.forEach((value) {
                var calendar = Calendar.fromLocalData(value);
                if ((selectedData.contains(calendar.id)
                    && UserCalendarsPermission.containsKey(calendar.id)
                    && UserCalendarsPermission[calendar.id]['add'] == 1)
                    || calendar.creator == autshUserData.uid) {

                  calendar.enable = false;
                  selectedCalendars.add(calendar);
                }
              });

            });
          }


        }
      setState(() {});

    }
  }


  void _eventOpen(FbEvent event) {

    print('event id - ${event.eventId}');
    event.importData.forEach((key, value) {
      print('$key - $value');
    });

    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
              appBar: AppBar(title: Text('event data'),),
              body: Container (
                margin: EdgeInsets.only(top: 20.0, left: 10.0, right: 10.0),
                child: ListView(
                  children: [
                    Center(
                        child: SelectableText("${event.name}",
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
                      child:  SelectableText("${event.descriptionString()}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Center(
                      child:  Text("${event.organizerName}",
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

  void _eventImport(FbEvent event) {
    calendarImportList = [];
    if (eventImportMap.containsKey(event.eventId)) {
      List eventImportsData = eventImportMap[event.eventId];

      eventImportsData.forEach((element) {
        calendarImportList.add(element['eventImportSourceId']);
      });
    }


    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
              appBar: AppBar(title: Text('event Import'),),
              body: ListView(
                children: [

                  if (selectedCalendars.length > 0)
                  Row (
                    children: [
                      Expanded(child: Text('select calendar', textAlign: TextAlign.center,),)
                    ],
                  ),
                  ListView.separated(
                    itemCount: selectedCalendars.length,
                    padding: EdgeInsets.only(left: 20),
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    separatorBuilder: (BuildContext context, int index) => Divider(
                      height: 10,
                      color: Colors.blueAccent,
                      thickness: 3,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      return Row(
                        textDirection: TextDirection.ltr,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(selectedCalendars[index].name,
                              style: TextStyle(
                                  fontSize: 15
                              ),),

                          if (calendarImportList.contains(selectedCalendars[index].id))
                            Container(
                                margin: const EdgeInsets.all(10.0),
                                child: Icon(Icons.verified, color: Colors.green,)
                            )
                          else
                            Checkbox(
                                value: selectedCalendars[index].enable,
                                onChanged: (bool? newValue) {
                                   selectedCalendars[index].enable = newValue!;
                                  setState(() {
                                  });

                                  Navigator.pop(context);
                                  _eventImport(event);
                                })
                        ],
                      );
                    },
                  ),

                  if (selectedCalendars.length > 0)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    child:   ElevatedButton(
                      onPressed: () => eventImport(event),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('export'),
                          Icon(Icons.upload_outlined, size: 15, color: Colors.white,),
                        ],
                      ),
                    ),
                  )

                ],
              ),
          );
        })
    );
  }

  
  void eventImport(event){
    List selected = [];
    selectedCalendars.forEach((calendar) {
      if (calendar.enable) {
        selected.add(calendar.id);
      }
    });

    if (selected.length > 0) {

      ApiSigned().then((signedData) {

        FbEvent fbEvent = event;

        var requestTokenData = {
          'tokenId': signedData['tokenId'],
          'signed': '${signedData['signed']}',
          'calendars': selected,
          'event': fbEvent.importToApi()
        };

        Navigator.pop(context);

        CalendarRepository().apiAddEvent(requestTokenData).then((request) {

          if (request.containsKey('errorMessage')) {
            shortMessage(context, "message - ${request['errorMessage']}", 2);
            debugPrint("error message - ${request['errorMessage']}");
            debugPrint("timeSighed - ${request['timeSighed']}");
          } else {
            debugPrint("response sugess");
            request['data'].forEach((item) {
              var importData = {
                'eventExportSourceId': 'fecebookEvents',
                'eventExportId': fbEvent.eventId,
                'eventImportSourceId': item['calId'],
                'eventImportId': item['eventId'],
              };

              CalendarRepository().addImportEventData(importData).then((value) {
                shortMessage(context, value, 2);
                if (eventImportMap.containsKey(fbEvent.eventId)) {
                  eventImportMap[fbEvent.eventId].add(importData);
                } else {
                  eventImportMap[fbEvent.eventId] = [importData];
                }
                calendarImportList.add(item['calId']);
                setState(() {});
              });
            });
          }


        });

      });
    } else {
      shortMessage(context, 'select calendar to import', 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('My Fb Events'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: _menuOpen,
          )
        ],
      ),
      body: _body(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete),
            label: 'clear',
          ),
          _calendarButton(),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightBlueAccent[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _body() {
    if (Events.length == 0)
      return Container(
        child:  Center(
          child: Column(
            children: [
              const SizedBox(height: 20.0),
              Text('empty data events'),
            ],
          ),
        ),
      );
    else
      return ListView.builder(
        itemCount: Events.length,
        shrinkWrap: true,
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
              onTap: () => _eventOpen(Events[index]),
              title: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(Events[index].timePeriod(),
                            textAlign: TextAlign.left,
                          ),
                      ),
                    ]
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                          child: Text(Events[index].name,
                            softWrap: true,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          )
                      ),
                    ]
                  ),
                ],
              ),
              subtitle: Row(
                children: [
                  Expanded (
                    child: Text('${Events[index].locationString()}'),
                  ),

                

                  if (selectedCalendars.length > 0
                  && eventImportMap.containsKey(Events[index].eventId))
                    ElevatedButton(
                      onPressed: () => _eventImport(Events[index]),
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue.shade900),
                      ),
                      child: Row(
                        children: [
                          Text('export  '),
                          Icon(Icons.verified, color: Colors.green, size: 18,),
                        ],
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _eventImport(Events[index]),
                      child: Row(
                        children: [
                          Text('export  '),
                          Icon(Icons.upload_outlined, size: 15, color: Colors.white,),
                        ],
                      ),
                    )

                ],
              ),
            ),
          );
        },
      );
  }

  Future<void> _onItemTapped(int index) async {
    switch (index) {
      case 0:
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
      case 1:
        FbEventsRepository().clearLocalDataJson('eventsUrl');
        FbEventsRepository().clearLocalDataJson('fbEvents');
        setState(() {
          Events = [];
          eventsUrl = '';
          _selectedIndex = index;
        });
        break;
      case 2:
        if (eventsUrl == '') {
          showDialog(context: context, builder: (BuildContext context) {
            return AlertDialog(
              title: Text('add Facebook calendar URL'),
              content: TextField(
                onChanged: (String value) {
                  eventsUrl = value;
                },
              ),
              actions: [
                ElevatedButton(onPressed: () {
                  FbEventsRepository().setLocalDataJson('eventsUrl', eventsUrl);
                  setState(() {
                    print(eventsUrl);
                  });
                  Navigator.of(context).pop();
                },
                    child: Text('save URL')
                )
              ],
            );
          });
        } else {
          await FbEventsRepository().getEventsList(eventsUrl);
          getEvents();
          setState(() {
            _selectedIndex = index;
          });
        }

        break;
    }
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
              ],
            ),
          );
        })
    );
  }
}
