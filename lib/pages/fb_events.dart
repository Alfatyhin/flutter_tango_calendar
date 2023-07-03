import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tango_calendar/AppTools.dart';
import 'package:tango_calendar/models/Event.dart';
import 'package:tango_calendar/models/FbEvent.dart';
import 'package:tango_calendar/models/Calendar.dart';
import 'package:tango_calendar/models/UserData.dart';
import 'package:tango_calendar/repositories/calendar/fb_events_repository.dart';

import 'package:tango_calendar/icalendar_parser.dart';
import 'package:tango_calendar/repositories/localRepository.dart';
import 'package:tango_calendar/repositories/users/users_reposirory.dart';
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
  int _selectedImportIndex = 0;
  bool _isLoading = false;
  var selectedData = [];
  List<Calendar> selectedCalendars = [];
  Map eventImportMap = {};
  List calendarImportList = [];
  late FbEvent activeEvent;
  Map FbImportSettings = {};
  Map calendarsImportData = {};
  var seeFilter = false;

  var openImportEventUpdate = false;

  var filterIcon;

  @override
  void initState() {
    super.initState();
    setFilterIcon();
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

    seeFilter = await localRepository().getLocalDataBool('seeFilter');

    print("test - $seeFilter");

    await calendarsMapped();

    print(calendarsTypesMap);

    List fbEventsIdsList = [];

    eventsUrl = (await FbEventsRepository().getLocalDataString('eventsUrl'))!;
    setState(() {

    });

    if (eventsUrl != '') {
      String fbCalendar = await FbEventsRepository().getLocalDataString('fbEvents') as String;

      if (fbCalendar != '') {
        final now = DateTime.now().toLocal();

        try {
          final iCalendar = ICalendar.fromString(fbCalendar);
          Events = [];

          iCalendar.data.forEach((element) {


            var dateTimeStart = DateTime.parse(element['dtstart'].dt).toLocal();
            var dateStart = DateFormatDate(dateTimeStart);
            var timeStart = DateFormatTime(dateTimeStart);

            var dateTimeEnd = DateTime.parse(element['dtend'].dt).toLocal();
            var dateEnd = DateFormatDate(dateTimeEnd);
            var timeEnd = DateFormatTime(dateTimeEnd);

            var date = DateTime.parse(element['lastModified'].dt);
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


          while(fbEventsIdsList.length > 0 ) {
            int size = 10;
            if (fbEventsIdsList.length < 10) {
              size = fbEventsIdsList.length;
            }
            List list = fbEventsIdsList.sublist(0, size);

            fbEventsIdsList.removeRange(0, size);

            await CalendarRepository().getImportEventDataIds(list as List).then((value) {
              value.forEach((element) {

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
            print(eventsUrl);
            eventsUrl = eventsUrl;
            Events = Events;
            _iCalendar = iCalendar;
            _isLoading = false;
          });
        } catch(e) {
          print(e);
        }

      }
    }

    ////
    var calendarsJson = await CalendarRepository().getLocalDataJson('calendars');
    var selectedCalendarsJson = await CalendarRepository().getLocalDataJson('selectedCalendars');


    selectedData = [];

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

              usersRepository().getFbEventImportSettingsByCalId(calendar.id).then((calImportSettings){
                FbImportSettings[calendar.id] = calImportSettings;
              });
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
                  usersRepository().getFbEventImportSettingsByCalId(calendar.id).then((calImportSettings){
                    FbImportSettings[calendar.id] = calImportSettings;
                  });
                }
              });

            });
          }


        }
      setState(() {});

    }
    setFilterIcon();

    // TODO: робити прокрутку до івенту
    if (backCommand['comand'] == 'import open') {
      _eventImport(backCommand['argument']);
      backCommand['comand'] = '';
      backCommand['argument'] = false;
    }
  }

  Future<void> setFilterIcon() async {

    if (seeFilter) {
      filterIcon = Icon(Icons.disabled_visible, color: Colors.black,);
    } else {
      filterIcon = Icon(Icons.remove_red_eye_rounded,);
    }
    setState(() {
      filterIcon = filterIcon;
    });
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
                      child:  ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: event.url));
                        },
                        child: Text('copy url event'),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Center(
                      child:  SelectableText("organizer - ${event.organizerName}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Center(
                      child:  ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: event.organizerName));
                        },
                        child: Text('copy organizer Name'),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ),
          );
        })
    );
  }

  void _eventImport(FbEvent event) {
    calendarImportList = [];
    calendarsImportData = {};

    activeEvent = event;
    print("eventId - ${event.eventId}");
    print(event.importData['location']);
    print(event.importData['geo']);

    if (eventImportMap.containsKey(event.eventId)) {
      List eventImportsData = eventImportMap[event.eventId];

      print(event.name);
      print("${event.getHashEvent()} -- ${eventImportsData[0]['hashEvent']}");

      eventImportsData.forEach((element) {
        calendarImportList.add(element['eventImportSourceId']);
        if (!selectedData.contains(element['eventImportSourceId'])) {
          selectedData.add(element['eventImportSourceId']);
          selectedCalendars.add(AllCalendars[element['eventImportSourceId']]);
        }
      });
    }

    var eventDate = DateTime.parse(event.dateStart);

    print("${event.dateStart} - ${event.dateEnd}");

    if (FbImportSettings.length == 0 || FbImportSettings.length < selectedCalendars.length) {
      selectedCalendars.forEach((calendar) async {

        if (!FbImportSettings.containsKey(calendar.id)) {

          print('get import settings - ${calendar.id}');
          usersRepository().getFbEventImportSettingsByCalId(calendar.id).then((calImportSettings){
            FbImportSettings[calendar.id] = calImportSettings;

            Navigator.pop(context);
            _eventImport(event);
          });
        }


      });

      print('import prepeare ${selectedCalendars.length} / ${FbImportSettings.length}');

    } else {

      print('import prepeare ${selectedCalendars.length} / ${FbImportSettings.length}');


      selectedCalendars.forEach((calendar) {
        if (FbImportSettings.containsKey(calendar.id)
            && FbImportSettings[calendar.id].length > 0) {

          if (kEvents.containsKey(eventDate)) {
            List dayEvents = kEvents[eventDate];

            dayEvents.forEach((value) {
              Event dayEvent = value;
              var checkEventId = dayEvent.eventId;

              var eventIdData = dayEvent.eventId.split('_');
              if (eventIdData.length > 0) {
                checkEventId = eventIdData[0];
              }


              if (dayEvent.calendarId == calendar.id
                  && FbImportSettings[calendar.id].containsKey(checkEventId)
                  && event.dateStart == event.dateEnd
                  && FbImportSettings[calendar.id][checkEventId]['fbOrgName'].contains(event.organizerName)) {

                calendarsImportData[calendar.id] = {
                  'evName': dayEvent.name,
                  'eventId': dayEvent.eventId,
                  'userUid': FbImportSettings[calendar.id][checkEventId]['userUid'],
                  'importEventData': {}
                };

                if (FbImportSettings[calendar.id][checkEventId]['importRules']['name'] != true) {
                  calendarsImportData[calendar.id]['importEventData']['name'] = dayEvent.name;
                }

                if (FbImportSettings[calendar.id][checkEventId]['importRules']['location'] != true) {
                  calendarsImportData[calendar.id]['importEventData']['location'] = dayEvent.locationString();
                }

                if (FbImportSettings[calendar.id][checkEventId]['importRules']['description'] != true) {
                  calendarsImportData[calendar.id]['importEventData']['description'] = dayEvent.description;
                }

                if (FbImportSettings[calendar.id][checkEventId]['userUid'] != autshUserData.uid) {
                  print('get user org');
                  usersRepository().getUserDataByUid(FbImportSettings[calendar.id][checkEventId]['userUid']).then((orgUserData) {
                    calendarsImportData[calendar.id]['importEventData']['organizer'] = {
                      'name': orgUserData.name,
                      'email': orgUserData.email
                    };
                  });
                }
              }
            });

          }

        }
      });
    }


    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Import', textAlign: TextAlign.left,),
              actions: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _topBarTapped(0);
                      },
                      child: Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_box_outlined),
                            Text('new calendar')
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),


                    GestureDetector(
                      onTap: () {
                        _topBarTapped(1);
                      },
                      child: Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_rounded),
                            Text('export')
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    GestureDetector(
                      onTap: () {
                        _topBarTapped(2);
                      },
                      child: Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.list_alt),
                            Text('calendars')
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                )

              ],
              // bottom: TabBar(
              //   tabs: <Widget>[
              //     Tab(
              //       icon: const Icon(Icons.cloud_outlined),
              //       text: 'test 1',
              //     ),
              //     Tab(
              //       icon: const Icon(Icons.beach_access_sharp),
              //       text: 'test 1',
              //     ),
              //     Tab(
              //       icon: const Icon(Icons.brightness_5_sharp),
              //       text: 'test 1',
              //     ),
              //   ],
              // ),
            ),
            body: ListView(
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
                    separatorBuilder: (BuildContext context, int index) {
                      if (!openImportEventUpdate || calendarImportList.contains(selectedCalendars[index].id))

                        return Divider(
                          height: 10,
                          color: Colors.blueAccent,
                          thickness: 3,
                        );
                      else
                        return Divider(
                          height: 0,
                          color: Colors.white,
                          thickness: 0,
                        );
                    },
                    itemBuilder: (BuildContext context, int index) {

                      if (openImportEventUpdate && calendarImportList.contains(selectedCalendars[index].id)) {
                        selectedCalendars[index].enable = true;
                      }

                      if (!openImportEventUpdate
                          || calendarImportList.contains(selectedCalendars[index].id)
                          || selectedCalendars[index].enable) {

                        return Row(
                          textDirection: TextDirection.ltr,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!openImportEventUpdate
                                || calendarImportList.contains(selectedCalendars[index].id)
                                || selectedCalendars[index].enable)

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text("${selectedCalendars[index].name}",
                                    style: TextStyle(
                                        fontSize: 15
                                    ),),

                                  if (calendarsImportData.containsKey(selectedCalendars[index].id))
                                    Text("to ${calendarsImportData[selectedCalendars[index].id]['evName']}",
                                      style: TextStyle(
                                          fontSize: 12
                                      ),),

                                  Text(selectedCalendars[index].typeEvents,
                                    style: TextStyle(
                                      fontSize: 10,
                                    ),),
                                ],
                              ),

                            if (!openImportEventUpdate
                                || calendarImportList.contains(selectedCalendars[index].id)
                                || selectedCalendars[index].enable)
                              Column(
                                children: [
                                  if (calendarImportList.contains(selectedCalendars[index].id))
                                    if (openImportEventUpdate)
                                      Checkbox(
                                          value: selectedCalendars[index].enable,
                                          onChanged: (bool? newValue) {
                                            selectedCalendars[index].enable = newValue!;
                                            setState(() {
                                            });

                                            Navigator.pop(context);
                                            _eventImport(event);
                                          })
                                    else
                                      Container(
                                          margin: const EdgeInsets.all(10.0),
                                          child: Icon(Icons.verified, color: Colors.green,)
                                      )
                                  else
                                    if((selectedCalendars[index].typeEvents != 'festivals'
                                        && event.dateStart == event.dateEnd)
                                        ||( event.dateStart != event.dateEnd ))
                                      Checkbox(
                                          value: selectedCalendars[index].enable,
                                          onChanged: (bool? newValue) {
                                            selectedCalendars[index].enable = newValue!;
                                            setState(() {
                                            });

                                            Navigator.pop(context);
                                            _eventImport(event);
                                          })
                                    else
                                      Container(
                                        // margin: const EdgeInsets.all(10.0),
                                        child:  Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [

                                                  Icon(Icons.warning_amber_outlined,
                                                    color: Colors.amber[900],
                                                  ),
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
                                              )
                                            ]
                                        ),
                                      ),

                                ],
                              ),

                          ],
                        );

                      } else {

                        return Container();

                      }
                    },
                  ),

                  if (selectedCalendars.length > 0)

                    Container(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        child:    Divider(
                          height: 10,
                          color: Colors.blueAccent,
                          thickness: 3,
                        ),
                    ),


                  const SizedBox(height: 20.0),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child:  SelectableText("organizer - ${event.organizerName}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 18),
                        ),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: event.organizerName));
                          },
                          child: Icon(Icons.copy),
                        ),
                      ],
                    )
                  ),


                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    child: Row (
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Uri url = Uri.parse(event.url);
                            _launchUrl(url);
                          },
                          child: Text('go event'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: event.url));
                          },
                          child: Text('copy url'),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            bottomNavigationBar: BottomNavigationBar(
              items:  <BottomNavigationBarItem>[
                if (autshUserData.role == 'su_admin'
                    || autshUserData.role == 'admin'
                    || autshUserData.role == 'organizer')

                  BottomNavigationBarItem(
                  icon: Icon(Icons.add),
                  label: 'add calendar',
                )
                else
                  BottomNavigationBarItem(
                    icon: Icon(Icons.add, size: 0,),
                    label: 'export',
                  ),

                if (!openImportEventUpdate)
                    BottomNavigationBarItem(

                      icon: Icon(Icons.upload_rounded, color: Colors.green, ),
                      label: 'export',
                    )
                else
                    BottomNavigationBarItem(

                      icon: Icon(Icons.refresh, color: Colors.green, ),
                      label: 'update',
                    ),

                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt),
                  label: 'calendars',
                ),
              ],
              currentIndex: _selectedImportIndex,
              selectedItemColor: Colors.lightBlueAccent[800],
              onTap: _onItemImportTapped,
            ),
          );
        })
    );
  }

  
  void eventImport(event){
    List selected = [];
    int x = 0;
    selectedCalendars.forEach((calendar) {
      if (calendar.enable) {
        selectedCalendars[x].enable = false;
        selected.add(calendar.id);
      }
      x++;
    });

    if (selected.length > 0) {

      ApiSigned().then((signedData) async {

        FbEvent fbEvent = event;

        if (openImportEventUpdate) {
          List eventsList = eventImportMap[fbEvent.eventId];
          print(eventsList);
          eventsList.forEach((element) {
            calendarsImportData[element['eventImportSourceId']] = {
              'eventId': element['eventImportId']
            };
          });
        }

        var requestTokenData = {
          'tokenId': signedData['tokenId'],
          'signed': '${signedData['signed']}',
          'calendars': selected,
          'event': fbEvent.importToApi(),
          'calendarsImportData': calendarsImportData
        };

        // eventImportMap = {};
        // CalendarRepository().testRequest(requestTokenData);

        Navigator.pop(context);

        await CalendarRepository().apiAddEvent(requestTokenData).then((request) {

          if (request.containsKey('errorMessage')) {
            debugPrint("error message - ${request['errorMessage']}");
            shortMessage(context, "error - ${request['errorMessage']['error']['message']}", 2);
          } else {
            debugPrint("response sugess");

            DateTime date = DateTime.now();

            request['data'].forEach((item) async {
              var importData = {
                'eventExportSourceId': 'fecebookEvents',
                'eventExportId': fbEvent.eventId,
                'eventImportSourceId': item['calId'],
                'eventImportId': item['eventId'],
                'endEventDate': fbEvent.dateEnd,
                'changeDate': DateFormatDateTime(date),
                'hashEvent': "${fbEvent.getHashEvent()}",
              };

              await CalendarRepository().addImportEventData(importData).then((value) async {
                shortMessage(context, value, 2);
                // await CalendarRepository().deleteImportEventDataOld(fbEvent.eventId).then((value) {
                //   shortMessage(context, 'events cleared', 2);
                // });
                calendarImportList.add(item['calId']);
                setState(() {});
              });

            });

            setState(() {
              _onItemTapped(2);
              shortMessage(context, 'events reload', 2);
            });
          }
        });

      });
    } else {
      shortMessage(context, 'select calendar to import', 2);
    }
  }

  void eventImportUpdate(event){
    List selected = [];
    eventImportMap[event.eventId].forEach((importItem) {
      print(importItem);
        selected.add(importItem['eventImportSourceId']);
    });

    if (selected.length > 0) {

      ApiSigned().then((signedData) async {

        FbEvent fbEvent = event;

        if (openImportEventUpdate) {
          List eventsList = eventImportMap[fbEvent.eventId];
          print(eventsList);
          eventsList.forEach((element) {
            calendarsImportData[element['eventImportSourceId']] = {
              'eventId': element['eventImportId']
            };
          });
        }

        var requestTokenData = {
          'tokenId': signedData['tokenId'],
          'signed': '${signedData['signed']}',
          'calendars': selected,
          'event': fbEvent.importToApi(),
          'calendarsImportData': calendarsImportData
        };

        await CalendarRepository().apiAddEvent(requestTokenData).then((request) {

          if (request.containsKey('errorMessage')) {
            debugPrint("error message - ${request['errorMessage']}");
            shortMessage(context, "error - ${request['errorMessage']['error']['message']}", 2);
          } else {
            debugPrint("response sugess");

            DateTime date = DateTime.now();

            request['data'].forEach((item) async {
              var importData = {
                'eventExportSourceId': 'fecebookEvents',
                'eventExportId': fbEvent.eventId,
                'eventImportSourceId': item['calId'],
                'eventImportId': item['eventId'],
                'endEventDate': fbEvent.dateEnd,
                'changeDate': DateFormatDateTime(date),
                'hashEvent': "${fbEvent.getHashEvent()}",
              };

              await CalendarRepository().addImportEventData(importData).then((value) async {
                shortMessage(context, value, 2);

              });

            });

          }
        });

      });
    } else {
      shortMessage(context, 'select calendar to import', 2);
    }
  }

  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
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
            child: Text('My Fb Events'),
          ),
          actions: [
            // IconButton(
            //   icon: Icon(Icons.menu),
            //   onPressed: _menuOpen,
            // )
          ],
        ),
        body: _body(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {

              if (seeFilter == true) {
                seeFilter = false;
              } else {
                seeFilter = true;
              }

              localRepository().setLocalDataBool('seeFilter', seeFilter);
              setFilterIcon();
            });
          },
          child: filterIcon,
        ),
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

      print("Events.length ${Events.length}");
      return ListView.builder(
        itemCount: Events.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {

          var updateEvent = false;

          if (eventImportMap.containsKey(Events[index].eventId)) {

            List importList = eventImportMap[Events[index].eventId];
            if (importList.length > 2) {
              // CalendarRepository().deleteImportEventDataOld(Events[index].eventId);
            }
            Map importFirst = importList[0];
            DateTime dateStart = DateTime.parse(Events[index].dateStart);
            List<Event> dayEvents = kEvents[dateStart] ?? [];
            if (!importFirst.containsKey('hashEvent')) {
              // print(Events[index].name);
              // print('no hashEvent');
              updateEvent = true;
            }
            if (importFirst.containsKey('hashEvent')
                && "${Events[index].getHashEvent()}" != importFirst['hashEvent']) {
              // print(Events[index].name);
              // print("${Events[index].getHashEvent()} -- ${importFirst['hashEvent']}");
              // eventImportUpdate(Events[index]);
              updateEvent = true;
            }
          }

          if ((selectedCalendars.length > 0
              && eventImportMap.containsKey(Events[index].eventId)
              && seeFilter == false)
              || updateEvent) {

            var importList = eventImportMap[Events[index].eventId] as List;

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
                        onPressed: () {
                          openImportEventUpdate = updateEvent;
                          _eventImport(Events[index]);
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue.shade900),
                        ),
                        child: Row(
                          children: [
                            Text('export  ${importList.length} '),
                            if (!updateEvent)
                              Icon(Icons.verified, color: Colors.green, size: 18,)
                            else
                              Icon(Icons.refresh, color: Colors.deepOrangeAccent, size: 18,)
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: ()  {
                          openImportEventUpdate = updateEvent;
                          _eventImport(Events[index]);
                        },
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

          } else {

            if (selectedCalendars.length > 0
                && eventImportMap.containsKey(Events[index].eventId)) {

              return Container();
            } else {

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
                          onPressed: ()  {
                            openImportEventUpdate = updateEvent;
                            _eventImport(Events[index]);
                          },
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
                          onPressed: ()  {
                            openImportEventUpdate = updateEvent;
                            _eventImport(Events[index]);
                          },
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
            }
          }
        },
      );
  }


  Future allCalendarsDialog(){

    List typesList = [];

    calendarsTypesMap.forEach((key, value) {
      var itemList = {
        'type': 'string',
        'value': "$key"
      };
      typesList.add(itemList);
      value.forEach((calId) {

        var itemList = {
          'type': 'calendar',
          'value': "$calId"
        };
        typesList.add(itemList);
      });
    });

    var itemList = {
      'type': 'close',
      'value': ""
    };
    typesList.add(itemList);


    return  showDialog(
      context: context,
      builder: (_) =>  Dialog(
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: typesList.length,
            itemBuilder: (BuildContext context, int index) {
              var typeEvent = typesList[index]['type'];

              if (typeEvent == 'string') {
                return Container (
                  margin: EdgeInsets.only(top: 0, left: 10.0, right: 10.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            const SizedBox(height: 8.0, ),

                            Text(typesList[index]['value'],
                              style: TextStyle(
                                  fontSize: 15,
                                fontWeight: FontWeight.w600
                              ),),

                          ],
                        )
                      ]
                  ),
                );

              } else if (typeEvent == 'calendar') {
                Calendar calendar = AllCalendars[typesList[index]['value']] as Calendar;

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
                            value:  selectedData.contains(calendar.id),
                            onChanged: (bool? newValue) {

                              if (!selectedData.contains(calendar.id)) {
                                print('test 1 ${calendar.id}');
                                selectedData.add(calendar.id);
                                calendar.enable = true;
                                List<Calendar> selected = [calendar];
                                selected.addAll(selectedCalendars);
                                selectedCalendars = selected;
                              } else {

                                print('test 2 ${calendar.id}');
                                selectedData.remove(calendar.id);
                                selectedCalendars = [];
                                selectedData.forEach((calId) {
                                  if (AllCalendars.containsKey(calId))
                                    selectedCalendars.add(AllCalendars[calId]);
                                });
                              }

                              Navigator.pop(context);
                              Navigator.pop(context);
                              _eventImport(activeEvent);


                            })

                      ]
                  ),
                );

              } else {
               return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                        onPressed: ()  {
                          Navigator.of(context).pop();

                        },
                        child: Text('close')
                    ),
                  ],
                );
              }
            }),
        ),
      anchorPoint: Offset(1000, 1000),
    );
  }

  Future<void> refreshEvents(index) async {
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
      await getEvents();
      setState(() {
        eventImportMap = eventImportMap;
        _selectedIndex = index;
      });
    }
  }

  Future<void> _onItemTapped(int index) async {
    switch (index) {
      case 0:
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
      case 1:
        FbEventsRepository().clearLocalDataJson('fbEvents');
        setState(() {
          Events = [];
          eventsUrl = '';
          _selectedIndex = index;
        });
        break;
      case 2:
        refreshEvents(index);

        break;
    }
  }

  Future<void> _topBarTapped(int index) async {
    switch (index) {
      case 0:
        if (autshUserData.role == 'su_admin'
            || autshUserData.role == 'admin'
            || autshUserData.role == 'organizer') {

          backRout = '/fb_events';
          backCommand['comand'] = 'import open';
          backCommand['argument'] = activeEvent;
          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(context, '/add_calendar', (route) => false);
        }
        break;
      case 1:
        if (selectedCalendars.length > 0)
          eventImport(activeEvent);
        else
          print(selectedCalendars);
        break;
      case 2:
        allCalendarsDialog();
        break;
    }
  }

  Future<void> _onItemImportTapped(int index) async {
    switch (index) {
      case 0:
        if (autshUserData.role == 'su_admin'
            || autshUserData.role == 'admin'
            || autshUserData.role == 'organizer') {

          backRout = '/fb_events';
          backCommand['comand'] = 'import open';
          backCommand['argument'] = activeEvent;
          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(context, '/add_calendar', (route) => false);
        }
        break;
      case 1:
        if (selectedCalendars.length > 0)
          eventImport(activeEvent);
        else
          print(selectedCalendars);
        break;
      case 2:
        allCalendarsDialog();
        break;
    }
  }

}
