import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import '../AppTools.dart';
import '../models/Calendar.dart';
import '../repositories/calendar/calendar_repository.dart';


class AddCalendar extends StatefulWidget {
  const AddCalendar({Key? key}) : super(key: key);

  @override
  _AddCalendarState createState() => _AddCalendarState();
}


class _AddCalendarState extends State<AddCalendar> {

  Map countriesCalendars = {};
  Map cityesCalendars = {};

  var countryValue;
  var stateValue;
  var cityValue;

  List calendarTypes = CalendarTypes().calendarTypes;
  Map calendarsCreatedrules = CalendarTypes().calendarCreatedRules;

  var calendarName;
  var selectCalendarType;

  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    setCalendarsMap();
  }

  Future<void> setCalendarsMap() async {
    var calendarsJson = await CalendarRepository().getLocalDataJson('calendars');

    if (calendarsJson != '') {
      List data = json.decode(calendarsJson as String);

      List calendarsData = data;

      calendarsData.forEach((value) {
        var calendar = Calendar.fromLocalData(value);

        if (countriesCalendars.containsKey(calendar.country) && calendar.city == ''
            && calendar.country != 'All') {


          Map item = countriesCalendars[calendar.country];
          item[calendar.typeEvents] = calendar;
          countriesCalendars[calendar.country].add(item);
        } else {
          if (calendar.country != 'All') {
            countriesCalendars[calendar.country] = [];
            Map item = countriesCalendars[calendar.country];
            item[calendar.typeEvents] = calendar;
            countriesCalendars[calendar.country].add(item);
          }
        }

        if (cityesCalendars.containsKey(calendar.city) && calendar.city != '') {

          cityesCalendars[calendar.city][calendar.typeEvents] = calendar;
        } else {
          cityesCalendars[calendar.city] = {};
          cityesCalendars[calendar.city][calendar.typeEvents] = calendar;
        }


      });

    }
  }


  Future calendarTypeDialog(){

    setCalendarsMap();
    List selectedList = [];

    print(countriesCalendars);

    Map userCalendarCreateRules = calendarsCreatedrules[autshUserData.role];

    calendarTypes.forEach((calType) {
     if (userCalendarCreateRules.containsKey(calType) && userCalendarCreateRules[calType] > 0 ) {

       var calTypeName = calType.replaceAll(RegExp(r'_'), ' ');
       Map type = {
         'type': calType,
         'typeDisplay': calTypeName,
         'enable': false,
         'selected': false
       };

       if ((calType == 'festivals' || calType == 'master_classes')
           && countryValue != null) {

         var countryData = countryValue.split('    ');
         print(countryData);
         type['name'] = "$calTypeName in ${countryData[1]}";
         selectedList.add(type);

       }

       if ((calType == 'festival_shedule'
           || calType == 'milongas'
           || calType == 'practices'
           || calType == 'tango_school')
           && cityValue != null) {

         type['name'] = "$calTypeName"
             " in $cityValue";
         selectedList.add(type);

       }

     }
    });


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
                            Checkbox(
                                value: selectedList[index]['enable'],
                                onChanged: (bool? newValue) {

                                  selectCalendarType = selectedList[index]['type'];
                                  calendarName = selectedList[index]['name'];
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
    return Scaffold(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (calendarName != null)
                  Expanded (
                    child: Text(calendarName),
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

          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete, color: Colors.white,),
            label: '',
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
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
      case 1:

        break;
      case 2:

        break;
    }

  }

}

