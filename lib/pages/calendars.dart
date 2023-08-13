import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tango_calendar/models/Calendar.dart';
import 'package:tango_calendar/repositories/localRepository.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../repositories/calendar/calendar_repository.dart';
import '../AppTools.dart';

class CalendarsPage extends StatefulWidget {
  const CalendarsPage({Key? key}) : super(key: key);

  @override
  _CalendarsPageState createState() => _CalendarsPageState();
}


List<TypeEvent> generateItems() {
  List typesEventsList = ['festivals', 'master classes', 'milongas', 'practices', 'tango school'];

  List<TypeEvent> types = [];
  typesEventsList.forEach((element) {
    var type = TypeEvent(headerValue: element);
    types.add(type);
  });

  return types;
}


class _CalendarsPageState extends State<CalendarsPage> {

  final List<TypeEvent> _dataTypes = generateItems();
  var AllCalendarsCount = 0;
  List calendarsList = [];
  var eventsWorld;
  List festivals = [];
  List masterClasses = [];
  List milongas = [];
  List practices = [];
  List tangoSchools = [];
  Map typesEventsGeoMap = {};
  Map filtersTypesEventsGeoMap = {
    'festivals': {
      'countries': []
    },
    'master classes': {
      'countries': []
    },
    'milongas': {
      'countries': [],
      'cities': []
    },
    'practices': {
      'countries': [],
      'cities': []
    },
    'tango school': {
      'countries': [],
      'cities': []
    },
  };
  Map viewCalendarsList = {};
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    setlocaleJsonData();
    calendarsMapped();
  }

  @override
  Future<void> setlocaleJsonData() async {
    Map selected = {};
    List selectedCalendars = [];
    calendarsList = [];
    festivals = [];
    masterClasses = [];
    practices = [];
    milongas = [];
    tangoSchools = [];
    typesEventsGeoMap = {};
    await calendarsMapped();
    AllCalendarsCount = AllCalendars.length;



    var filtersTypesEventsGeoMapJson = await CalendarRepository().getLocalDataJson('filtersTypesEventsGeoMap');

    if (filtersTypesEventsGeoMapJson != '') {
      filtersTypesEventsGeoMap = json.decode(filtersTypesEventsGeoMapJson as String);
    }

    var calendarsJson = await CalendarRepository().getLocalDataJson('calendars');
    var selectedCalendarsJson = await CalendarRepository().getLocalDataJson('selectedCalendars');

    if (selectedCalendarsJson != '') {
      selectedCalendars = json.decode(selectedCalendarsJson as String);
    }

    if (selectedCalendars.length > 0) {
      print(selectedCalendars);
      for(var x = 0; x < selectedCalendars.length; x++) {
        var key = selectedCalendars[x];
        selected["$key"] = true;
      }
    } else {
      print('not selected');
    }

    if (calendarsJson != '') {
      List data = json.decode(calendarsJson as String);

      List calendarsData = data;

      int xl = 0;
      calendarsData.forEach((value) {
        var calendar = Calendar.fromLocalData(value);

        if (selectedCalendars.length > 0 && selected.containsKey(value['id'])) {
          calendar.enable = true;
        }

        calendarsList.add(calendar);

        var calTypeName = calendar.typeEvents.replaceAll(RegExp(r'_'), ' ');

        if (calendar.country != 'All') {

          if (!typesEventsGeoMap.containsKey(calTypeName)) {
            typesEventsGeoMap[calTypeName] = {
              'countries': [],
              'cities': {}
            };
          }

          if (!typesEventsGeoMap[calTypeName]['countries'].contains(calendar.country)) {
            typesEventsGeoMap[calTypeName]['countries'].add(calendar.country);
          }

          if (calendar.city != '') {

            if (!typesEventsGeoMap[calTypeName]['cities'].containsKey(calendar.country)) {
              typesEventsGeoMap[calTypeName]['cities'][calendar.country] = [];
            }
            if (!typesEventsGeoMap[calTypeName]['cities'][calendar.country].contains(calendar.city)) {
              typesEventsGeoMap[calTypeName]['cities'][calendar.country].add(calendar.city);
            }

          }
        }





        switch(calendar.typeEvents) {
          case 'festivals':
            if (calendar.country != 'All') {
              festivals.add(xl);
            } else {
              List events = [xl];
              events.addAll(festivals);
              festivals = events;
            }
            break;
          case 'master_classes':
            masterClasses.add(xl);
            break;
          case 'milongas':
            milongas.add(xl);
            break;
          case 'practices':
            practices.add(xl);
            break;
          case 'tango_school':
            tangoSchools.add(xl);
        }
        xl++;
      });


      setState(() {
        _dataTypes[0].eventCalendars = festivals;
        _dataTypes[1].eventCalendars = masterClasses;
        _dataTypes[2].eventCalendars = milongas;
        _dataTypes[3].eventCalendars = practices;
        _dataTypes[4].eventCalendars = tangoSchools;

        typesEventsGeoMap = typesEventsGeoMap;
      });

    }
  }


  Future calendarGeoSettingsDialog([fresh = false]){

    if (fresh) {
      Navigator.of(context).pop();
    }

    // print(typesEventsGeoMap);

    return  showDialog(
      context: context,
      builder: (_) =>  Dialog(
        child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Center(
                  child: Text(AppLocalizations.of(context)!.geoFiltersToCalendarsList,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue
                    ),
                  ),
                ),
                ListView.builder(
                    shrinkWrap: true,
                    itemCount: _dataTypes.length,
                    itemBuilder: (BuildContext context, int index) {

                      var typeEvents = _dataTypes[index].headerValue;
                      Map typeEventsData = typesEventsGeoMap[typeEvents];
                      // print(typeEvents);
                      // print(typeEventsData);

                      return Container(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            Center (
                              child: Text(_dataTypes[index].headerValue,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            if (_dataTypes[index].headerValue == 'festivals'
                                || _dataTypes[index].headerValue == 'master classes')
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        filterCoutriesSettingsDialog(typeEvents, typeEventsData['countries']);
                                      },
                                      child: Text('${AppLocalizations.of(context)!.countries} ${filtersTypesEventsGeoMap[typeEvents]['countries'].length}/${typeEventsData['countries'].length}'),

                                    ),
                                  ]
                              )
                            else
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        filterCoutriesSettingsDialog(typeEvents, typeEventsData['countries']);
                                      },
                                      child: Text('${AppLocalizations.of(context)!.countries} ${filtersTypesEventsGeoMap[typeEvents]['countries'].length}/${typeEventsData['countries'].length}'),

                                    ),

                                    if (filtersTypesEventsGeoMap[typeEvents]['countries'].length > 0)
                                      Text(''),
                                    ElevatedButton(
                                      onPressed: () {
                                        filterCitiesSettingsDialog(typeEvents, typeEventsData['cities']);
                                      },
                                      child: Text('${AppLocalizations.of(context)!.cities} ${filtersTypesEventsGeoMap[typeEvents]['cities'].length}'),

                                    ),
                                  ]
                              ),

                            Divider(
                              height: 10,
                              color: Colors.blueAccent,
                              thickness: 3,
                            ),

                          ],
                        ),
                      );

                    }),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          localRepository().setLocalDataJson('filtersTypesEventsGeoMap', filtersTypesEventsGeoMap);
                          Navigator.of(context).pop();
                        },
                        child: Text(AppLocalizations.of(context)!.close)
                    ),
                  ],
                )
              ],
            )
        ),
      ),
      anchorPoint: Offset(1000, 1000),
    );
  }


  Future filterCoutriesSettingsDialog(typeEvent, countries){

    var all = false;
    if(filtersTypesEventsGeoMap[typeEvent]['countries'].length == 0) {
      all = true;
    }

    return  showDialog(
      context: context,
      builder: (_) =>  Dialog(
        child: Container(
            padding: EdgeInsets.all(20),
            child: ListView(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(AppLocalizations.of(context)!.countries,
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue
                            ),
                          ),
                        ),

                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('All',
                                style: TextStyle(
                                    fontSize: 15
                                ),),
                              Checkbox(
                                  value:  all,
                                  onChanged: (bool? newValue) {
                                    filtersTypesEventsGeoMap[typeEvent]['countries'] = [];
                                    setState(() {
                                      Navigator.pop(context);
                                      filterCoutriesSettingsDialog(typeEvent, countries);
                                    });
                                  })
                            ]
                        ),
                        Divider(
                          height: 10,
                          color: Colors.blueAccent,
                          thickness: 3,
                        ),

                        Column(
                          children: List<Widget>.generate(
                              countries.length,
                                  (int index) {
                                return Column(
                                  children: [
                                    Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(countries[index],
                                            style: TextStyle(
                                                fontSize: 15
                                            ),),
                                          Checkbox(
                                              value: filtersTypesEventsGeoMap[typeEvent]['countries'].contains(countries[index]),
                                              onChanged: (bool? newValue) {
                                                if (!filtersTypesEventsGeoMap[typeEvent]['countries'].contains(countries[index])) {
                                                  filtersTypesEventsGeoMap[typeEvent]['countries'].add(countries[index]);
                                                } else {
                                                  filtersTypesEventsGeoMap[typeEvent]['countries'].remove(countries[index]);
                                                }
                                                setState(() {
                                                  Navigator.pop(context);
                                                  filterCoutriesSettingsDialog(typeEvent, countries);
                                                });
                                              })
                                        ]
                                    ),

                                    Divider(
                                      height: 10,
                                      color: Colors.blueAccent,
                                      thickness: 3,
                                    ),
                                  ],
                                );
                              }
                          ),
                        ),

                      ],
                    ),


                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                            onPressed: ()  {
                              Navigator.of(context).pop();

                              calendarGeoSettingsDialog(true);
                            },
                            child: Text(AppLocalizations.of(context)!.close)
                        ),
                      ],
                    )
                  ],
                )
              ],
            )
        ),
      ),
      anchorPoint: Offset(1000, 1000),
    );
  }



  Future filterCitiesSettingsDialog(typeEvent, Map citiesData){

    List countries = [];

    citiesData.forEach((key, value) {
      countries.add(key);
    });

    var all = false;
    if(filtersTypesEventsGeoMap[typeEvent]['cities'].length == 0) {
      all = true;
    }

    return  showDialog(
      context: context,
      builder: (_) =>  Dialog(
        child: Container(
          padding: EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Center(
                        child: Text(AppLocalizations.of(context)!.cities,
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue
                          ),
                        ),
                      ),

                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('All',
                              style: TextStyle(
                                  fontSize: 15
                              ),),
                            Checkbox(
                                value:  all,
                                onChanged: (bool? newValue) {
                                  filtersTypesEventsGeoMap[typeEvent]['cities'] = [];
                                  setState(() {
                                    Navigator.pop(context);
                                    // filterCoutriesSettingsDialog(typeEvent, countries);
                                  });
                                })
                          ]
                      ),

                      Divider(
                        height: 10,
                        color: Colors.blueAccent,
                        thickness: 3,
                      ),


                      Column(
                        children: List<Widget>.generate(
                            countries.length,
                                (int index) {
                              return Column(
                                children: [
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(countries[index],
                                          style: TextStyle(
                                              fontSize: 15,
                                            fontWeight: FontWeight.w600
                                          ),),

                                      ]
                                  ),

                                  Divider(
                                    height: 10,
                                    color: Colors.blueAccent,
                                    thickness: 3,
                                  ),

                                  Column(
                                    children: List<Widget>.generate(
                                        citiesData[countries[index]].length,
                                            (int indexCity) {

                                              var cityName = citiesData[countries[index]][indexCity];
                                              return Container(
                                                padding: EdgeInsets.only(left: 10),
                                                child:  Column(
                                                  children: [
                                                    Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(cityName,
                                                            style: TextStyle(
                                                                fontSize: 15
                                                            ),),

                                                          Checkbox(
                                                              value: filtersTypesEventsGeoMap[typeEvent]['cities'].contains(cityName),
                                                              onChanged: (bool? newValue) {
                                                                if (!filtersTypesEventsGeoMap[typeEvent]['cities']
                                                                    .contains(
                                                                    cityName)) {
                                                                  filtersTypesEventsGeoMap[typeEvent]['cities']
                                                                      .add(cityName);
                                                                } else {
                                                                  filtersTypesEventsGeoMap[typeEvent]['cities']
                                                                      .remove(cityName);
                                                                }
                                                                setState(() {
                                                                  Navigator.pop(
                                                                      context);
                                                                  filterCitiesSettingsDialog(typeEvent, citiesData);
                                                                });
                                                              }
                                                          )

                                                        ]
                                                    ),
                                                    Divider(
                                                      height: 2,
                                                      color: Colors.blueAccent,
                                                      thickness: 1,
                                                    ),
                                                  ],
                                                ),
                                              );
                                        }
                                    ),
                                  )

                                ],
                              );
                            }
                        ),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                          onPressed: ()  {
                            Navigator.of(context).pop();

                            calendarGeoSettingsDialog(true);
                          },
                          child: Text(AppLocalizations.of(context)!.close)
                      ),
                    ],
                  )
                ],
              ),

            ],
          ),
        ),
      ),
      anchorPoint: Offset(1000, 1000),
    );
  }

  void selectCalendar() {
    List selected = [];
    for(var x = 0; x < calendarsList.length; x++) {
      var enable = calendarsList[x].enable;
      if (enable) {
        selected.add(calendarsList[x].id);
        selectedCalendars[calendarsList[x].id] = calendarsList[x];
      } else {
        selectedCalendars.remove(calendarsList[x].id);
      }
    }
    print(selected);
    print(selectedCalendars);
    var data = json.encode(selected);
    CalendarRepository().setLocalDataJson('selectedCalendars', data);
    backCommand['comand'] = 'refresh';
  }

  @override
  Widget build(BuildContext context) {

    List typesEventsList = ['festivals', 'master classes', 'milongas', 'practices', 'tango school'];
    Map translateTypes = {
      'festivals': AppLocalizations.of(context)!.festivals,
      'master classes': AppLocalizations.of(context)!.masterClasses,
      'festivals': AppLocalizations.of(context)!.festivals,
      'festivals': AppLocalizations.of(context)!.festivals,
      'festivals': AppLocalizations.of(context)!.festivals,
    };

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(AppLocalizations.of(context)!.calendarS),
          ),
          actions: [
            // IconButton(
            //   icon: Icon(Icons.menu),
            //   onPressed: _menuOpen,
            // )
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
                children: [

                  _buildPanel(),

                  const SizedBox(height: 20),
                  if (AllCalendarsCount != 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              calendarGeoSettingsDialog();
                            },
                            child: Text(AppLocalizations.of(context)!.settingsGeo)
                        )
                      ],
                    ),

                  if (selectedCalendars.length == 0)
                    Column(
                      children: [
                        const SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.calendarsNotSelected,
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 20
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                ]
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
              icon: Icon(Icons.delete),
              label: AppLocalizations.of(context)!.clear,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.refresh),
              label: AppLocalizations.of(context)!.updateList,
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.lightBlueAccent[800],
          onTap: _onItemTapped,
        ),
      ),
    );
  }



  Widget _buildPanel() {

    // TODO: модернізувати списки під прокрутку
    if (AllCalendarsCount == 0)
      return ElevatedButton.icon(
          onPressed: () async {
            _shortMessage('upload calendars', 2);
            await CalendarRepository().updateCalendarsData();
            await setlocaleJsonData();
            _shortMessage('upload complit', 2);

            Navigator.pop(context);
            Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);
          },
          icon: Icon(Icons.download_rounded),
          label: Text('download calendars')
      );
    else
      return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _dataTypes[index].isExpanded = !isExpanded;
        });
      },
      children: _dataTypes.map<ExpansionPanel>((TypeEvent item) {


        String typeEvent = item.headerValue;
        var itemEventCalendars = item.eventCalendars;
        var calendar;

        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {

            return ListTile(
              title: Text(
                typeEvent,
                style: TextStyle(
                    fontSize: 20
                ),),
            );
          },
          body: ListView.separated(
            itemCount: item.eventCalendars.length,
            padding: EdgeInsets.only(left: 20),
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            separatorBuilder: (BuildContext context, int index) {
              if ( calendar.country == 'All'
                  || (filtersTypesEventsGeoMap[typeEvent]['countries'].length == 0
                      && (filtersTypesEventsGeoMap[typeEvent].containsKey('cities')
                          && filtersTypesEventsGeoMap[typeEvent]['cities'].length == 0))
                  || (filtersTypesEventsGeoMap[typeEvent]['countries'].length == 0
                      && !filtersTypesEventsGeoMap[typeEvent].containsKey('cities'))
                  || (!filtersTypesEventsGeoMap[typeEvent].containsKey('cities')
                      && filtersTypesEventsGeoMap[typeEvent]['countries'].contains(calendar.country))
                  || (filtersTypesEventsGeoMap[typeEvent].containsKey('cities')
                      && filtersTypesEventsGeoMap[typeEvent]['cities'].length == 0
                      && filtersTypesEventsGeoMap[typeEvent]['countries'].contains(calendar.country))
                  || (filtersTypesEventsGeoMap[typeEvent].containsKey('cities')
                      && filtersTypesEventsGeoMap[typeEvent]['cities'].length > 0
                      && filtersTypesEventsGeoMap[typeEvent]['cities'].contains(calendar.city))
              )
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
            } ,
            itemBuilder: (BuildContext context, int index) {

              calendar = calendarsList[item.eventCalendars[index]] as Calendar;

              if ( calendar.country == 'All'
                  || (filtersTypesEventsGeoMap[typeEvent]['countries'].length == 0
                      && (filtersTypesEventsGeoMap[typeEvent].containsKey('cities')
                          && filtersTypesEventsGeoMap[typeEvent]['cities'].length == 0))
                  || (filtersTypesEventsGeoMap[typeEvent]['countries'].length == 0
                      && !filtersTypesEventsGeoMap[typeEvent].containsKey('cities'))
                  || (!filtersTypesEventsGeoMap[typeEvent].containsKey('cities')
                      && filtersTypesEventsGeoMap[typeEvent]['countries'].contains(calendar.country))
                  || (filtersTypesEventsGeoMap[typeEvent].containsKey('cities')
                      && filtersTypesEventsGeoMap[typeEvent]['cities'].length == 0
                      && filtersTypesEventsGeoMap[typeEvent]['countries'].contains(calendar.country))
                  || (filtersTypesEventsGeoMap[typeEvent].containsKey('cities')
                      && filtersTypesEventsGeoMap[typeEvent]['cities'].length > 0
                      && filtersTypesEventsGeoMap[typeEvent]['cities'].contains(calendar.city))
              ) {

                return  Row(
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
              } else {
                return  const SizedBox(height: 0);
              }


            },
          ),
          isExpanded: item.isExpanded,
        );
      }).toList(),
    );
  }

  Future<void> _onItemTapped(int index) async {
    switch (index) {
      case 0:
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
      case 1:
        await CalendarRepository().clearLocalDataJson('eventsJson');
        await CalendarRepository().clearLocalDataJson('calendars');
        await localRepository().clearLocalData('filtersTypesEventsGeoMap');
        _shortMessage('calendars deleted', 2);
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);
        break;
      case 2:
        _shortMessage('upload calendars', 2);
        await CalendarRepository().updateCalendarsData();
        await setlocaleJsonData();
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
