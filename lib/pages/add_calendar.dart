import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'package:tango_calendar/repositories/localRepository.dart';
import '../AppTools.dart';
import '../models/Calendar.dart';
import '../repositories/calendar/calendar_repository.dart';


class AddCalendar extends StatefulWidget {
  const AddCalendar({Key? key}) : super(key: key);

  @override
  _AddCalendarState createState() => _AddCalendarState();
}

// TODO: сделать перезапись списка стран при обновлении списка календарей


enum CalendarAddMode { newCalendar, issetCalendar }

class _AddCalendarState extends State<AddCalendar> {

  CalendarAddMode? _calendarAddMode = CalendarAddMode.newCalendar;
  String calendarAddMode = "newCalendar";

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController calendarUidController = TextEditingController();
  TextEditingController calendarNameController = TextEditingController();
  TextEditingController calendarDescriptionController = TextEditingController();

  Map countriesCalendars = {};
  Map cityesCalendars = {};

  var countryValue;
  var countryName = '';
  var stateValue;
  var cityValue = '';

  List calendarTypes = CalendarTypes().calendarTypes;
  Map calendarsCreatedrules = CalendarTypes().calendarCreatedRules;

  var selectCalendarDisplayName;
  var selectCalendarType;

  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    setCalendarsMap();
  }

  Future<void> setCalendarsMap() async {

    await CalendarRepository().updateCalendarsData();
    var calendarsJson = await CalendarRepository().getLocalDataJson('calendars');

    if (calendarsJson != '') {

      countriesCalendars = {};
      cityesCalendars = {};

      List data = json.decode(calendarsJson as String);

      List calendarsData = data;

      calendarsData.forEach((value) {
        var calendar = Calendar.fromLocalData(value);

        if (calendar.country != 'All' && calendar.city == '') {
          if (countriesCalendars.containsKey(calendar.country) ) {
            countriesCalendars[calendar.country].add(calendar.typeEvents);
          } else {
              countriesCalendars[calendar.country] = [];
              countriesCalendars[calendar.country].add(calendar.typeEvents);
          }
        }


        if (calendar.city != '') {
          if (cityesCalendars.containsKey(calendar.city)) {

            cityesCalendars[calendar.city].add(calendar.typeEvents);
          } else {
            cityesCalendars[calendar.city] = [];
            cityesCalendars[calendar.city].add(calendar.typeEvents);
          }

        }


      });

      shortMessage(context, 'calendars updated', 2);
      setState(() {});
    }
  }


  Future calendarTypeDialog(){

    List selectedList = [];

    print(countriesCalendars);
    print(cityesCalendars);
    print(countryValue);


    Map userCalendarCreateRules = calendarsCreatedrules[autshUserData.role];

    calendarTypes.forEach((calType) {

      print(autshUserData.role);
      print(calType);
      print(userCalendarCreateRules[calType]);

     if (userCalendarCreateRules.containsKey(calType) && userCalendarCreateRules[calType] > 0 ) {

       var calTypeName = calType.replaceAll(RegExp(r'_'), ' ');
       Map type = {
         'type': calType,
         'typeDisplay': calTypeName,
         'isset': false,
         'enable': false,
         'close': false
       };
       if (selectCalendarType == calType) {
         type['enable'] = true;
       }

       if ((calType == 'festivals' || calType == 'master_classes')
           && countryValue != null) {

         var countryData = countryValue.split('    ');
         type['name'] = "$calTypeName in ${countryData[1]}";
         countryName = countryData[1];

         if (countriesCalendars.containsKey(countryData[1])
             && countriesCalendars[countryData[1]].contains(calType)) {
           type['isset'] = true;
         }

         selectedList.add(type);

       }

       if ((calType == 'festival_shedule'
           || calType == 'milongas'
           || calType == 'practices'
           || calType == 'tango_school')
           && cityValue != '') {

         type['name'] = "$calTypeName in $cityValue";

         if (cityesCalendars.containsKey(cityValue)
             && cityesCalendars[cityValue].contains(calType)
             && (calType == 'milongas' || calType == 'practices')) {
           type['isset'] = true;
         }
         selectedList.add(type);

       }

     }
    });

    print(selectedList);


    return  showDialog(
      context: context,
      builder: (_) =>  Dialog(
        child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ListView.separated(
                  itemCount: selectedList.length,
                  // padding: EdgeInsets.only(left: 20),
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                  separatorBuilder: (BuildContext context, int index) => Divider(
                    height: 10,
                    color: Colors.blueAccent,
                    thickness: 3,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded (
                          child: Text("${selectedList[index]['name']}",
                            style: TextStyle(
                                fontSize: 15
                            ),),
                        ),

                        Column(
                          children: [
                            if (selectedList[index]['isset'])
                              Text('isset',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600
                                ),
                              )
                            else
                              Checkbox(
                                  value: selectedList[index]['enable'],
                                  onChanged: (bool? newValue) {

                                    selectCalendarType = selectedList[index]['type'];
                                    if (selectCalendarType == 'festival_shedule'
                                        || selectCalendarType == 'tango_school') {
                                      calendarNameController.text = '';
                                    } else {
                                      calendarNameController.text = selectedList[index]['name'];
                                    }
                                    selectCalendarDisplayName = selectedList[index]['name'];
                                    int x = 0;
                                    selectedList.forEach((value) {
                                      selectedList[x]['enable'] = false;
                                      x++;
                                    });
                                    selectedList[index]['enable'] = newValue!;

                                    setState(() {
                                    });

                                    Navigator.of(context).pop();

                                  })
                          ],
                        ),

                      ],
                    );
                  },
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                        onPressed: () => {
                          Navigator.of(context).pop()
                        },
                        child: Text('close')
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



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('Add Calendar'),
          ),
          actions: [

          ],
        ),
        body: Container(
          padding: EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            children: [
              SelectState(
                onCountryChanged: (value) {
                  setState(() {
                    countryValue = value;
                  });
                },
                onStateChanged:(value) {
                  setState(() {
                    stateValue = value;
                  });
                },
                onCityChanged:(value) {
                  setState(() {
                    cityValue = value;
                  });
                },
              ),

              const SizedBox(height: 20.0),
              Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (selectCalendarDisplayName != null)
                            Expanded (
                              child: Text(selectCalendarDisplayName),
                            )
                          else
                            Expanded (
                              child: Text('select type calendar'),
                            ),

                          ElevatedButton(
                            onPressed: () {
                              calendarTypeDialog();
                            }, child: Text('select',
                            style: TextStyle(
                                fontSize: 20
                            ),),),
                        ],
                      ),
                      const SizedBox(height: 20.0),

                      if ((selectCalendarType == 'festival_shedule'
                          || selectCalendarType == 'tango_school'))

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            Column(
                              children: [

                                Text("create new"),

                                Radio<CalendarAddMode>(
                                  value: CalendarAddMode.newCalendar,
                                  groupValue: _calendarAddMode,
                                  onChanged: (CalendarAddMode? value) {
                                    setState(() {
                                      _calendarAddMode = value;
                                      calendarAddMode = "newCalendar";

                                    });
                                  },
                                ),
                              ],
                            ),


                            Column(
                              children: [

                                Text("add isset"),

                                Radio<CalendarAddMode>(
                                  value: CalendarAddMode.issetCalendar,
                                  groupValue: _calendarAddMode,
                                  onChanged: (CalendarAddMode? value) {
                                    setState(() {
                                      _calendarAddMode = value;
                                      calendarAddMode = "issetCalendar";

                                    });
                                  },
                                ),
                              ],
                            ),

                          ],
                        ),



                      if ((selectCalendarType == 'festival_shedule'
                          || selectCalendarType == 'tango_school')
                          && calendarAddMode == 'issetCalendar')
                        Column(
                          children: [
                            const SizedBox(height: 20.0),

                            TextFormField(
                              controller: calendarUidController,
                              decoration: const InputDecoration(
                                labelText: 'calendar uid',
                                disabledBorder: OutlineInputBorder(),
                                hintText: 'UID Calendar',
                                border: OutlineInputBorder(),
                              ),
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter some UID';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),


                      if ((selectCalendarType == 'festival_shedule'
                          || selectCalendarType == 'tango_school')
                          && calendarAddMode == 'newCalendar')
                        TextFormField(
                          controller: calendarNameController,
                          decoration: const InputDecoration(
                            labelText: 'calendar name',
                            disabledBorder: OutlineInputBorder(),
                            hintText: 'Name Calendar',
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

                      if ((selectCalendarType == 'festival_shedule'
                          || selectCalendarType == 'tango_school')
                          && calendarAddMode == 'newCalendar')
                        Container(
                          height: 200,
                          child: TextField(
                            controller: calendarDescriptionController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Event Description'
                            ),
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            expands: true, // <-- SEE HERE
                          ),
                        ),


                    ],
                  )
              ),

              const SizedBox(height: 20.0),
              if (selectCalendarDisplayName != null)
                ElevatedButton(
                  onPressed: () {

                    if (selectCalendarType == 'festival_shedule'
                        || selectCalendarType == 'tango_school') {
                      if (_formKey.currentState!.validate()) {

                        addCalendar();
                        shortMessage(context, 'process added', 2);
                      }
                    } else {
                      addCalendar();
                      shortMessage(context, 'process added', 2);
                    }

                  }, child: Text('create calendar',
                  style: TextStyle(
                      fontSize: 20
                  ),),),
            ],
          ),
        ),

        bottomNavigationBar: BottomNavigationBar(
          items:  <BottomNavigationBarItem>[

            if (backRout != '')
              BottomNavigationBarItem(
                icon: Icon(Icons.arrow_back),
                label: 'back',
              )
            else
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'home',
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
      ),
    );
  }

  void addCalendar() {

    ApiSigned().then((signedData) {

      selectCalendarDisplayName = null;
      setState(() {});

      var data = {
        'name': calendarNameController.text,
        'description': calendarDescriptionController.text,
        'country': countryName,
        'city': cityValue,
        'type_events': selectCalendarType,
        'source': autshUserData.role,
        'addMode': calendarAddMode
      };

      if (calendarAddMode == 'issetCalendar') {
        data['uid'] =  calendarUidController.text;
      }

      print(data);
      var requestTokenData = {
        'tokenId': signedData['tokenId'],
        'signed': '${signedData['signed']}',
        'data': data
      };

      CalendarRepository().testRequest(requestTokenData);
      CalendarRepository().addGCalendarToApi(requestTokenData).then((response) {

        if (response.containsKey('errorMessage')) {
          debugPrint("error message - ${response['errorMessage']}");
          shortMessage(context, "error - ${response['errorMessage']['error']['message']}", 2);
        } else {

          Calendar calendar = new Calendar(
            id: "${response['id']}",
            name: "${response['name']}",
            description: response['description'],
            typeEvents: response['type_events'],
            country: response['country'],
            city: cityValue,
            source: response['source'],
            gcalendarId: "${response['gcalendarId']}",
            creator: autshUserData.uid,
          );

          print(calendar.toJson());
          CalendarRepository().addNewCalendarToFirebase(calendar).then((value) async {


            if (cityValue == '') {
              if (countriesCalendars.containsKey(countryName) ) {
                countriesCalendars[countryName].add(selectCalendarType);
              } else {
                countriesCalendars[countryName] = [];
                countriesCalendars[countryName].add(selectCalendarType);
              }
            }

            selectCalendarDisplayName = null;
            setState(() {});

            var selectedCalendarsJson = await CalendarRepository().getLocalDataJson('selectedCalendars');

            if (selectedCalendarsJson != '') {
              List selectedCalendars = json.decode(selectedCalendarsJson as String);
              selectedCalendars.add(response['id']);
              await localRepository().setLocalDataJson('selectedCalendars', selectedCalendars);
            }

            await CalendarRepository().updateCalendarsData();
            setCalendarsMap();
            shortMessage(context, 'calendar add', 2);

            if (backRout != '') {
              String redirect = backRout;
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, redirect, (route) => false);
            }

          });

        }
      });


    });

  }

  void _onItemTapped(int index) async {
    switch (index) {
      case 0:
        if (backRout != '') {
          String redirect = backRout;
          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(context, redirect, (route) => false);
        } else {

          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
        break;
      case 1:
        countriesCalendars = {};
        cityesCalendars = {};
        CalendarRepository().updateCalendarsData().then((value) {
          setCalendarsMap().then((value) {
            shortMessage(context, 'upload complit', 2);
            selectCalendarDisplayName = null;
            setState(() {});
          });

        });

        break;
    }

  }

}

