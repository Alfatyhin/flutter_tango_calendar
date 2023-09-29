import 'package:flutter/material.dart';
import 'package:tango_calendar/models/Calendar.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../AppTools.dart';
import '../repositories/calendar/calendar_repository.dart';
import '../repositories/users/users_reposirory.dart';
import '../utils.dart';
import 'package:intl/intl.dart';


class CreateEvent extends StatefulWidget {
  const CreateEvent({Key? key}) : super(key: key);

  @override
  _CreateEventState createState() => _CreateEventState();
}


class _CreateEventState extends State<CreateEvent> {

  final GlobalKey<FormState> _form = GlobalKey();
  TextEditingController calendarNameController = TextEditingController();
  TextEditingController eventTitleController = TextEditingController();
  TextEditingController eventDescriptionController = TextEditingController();
  TextEditingController eventLocationnController = TextEditingController();
  TextEditingController dateStartStringController = TextEditingController();
  TextEditingController dateEndStringController = TextEditingController();
  TextEditingController timeStartStringController = TextEditingController();
  TextEditingController timeEndStringController = TextEditingController();

  String _timezone = 'Unknown';
  DateTime dateStart = DateTime.now();
  DateTime dateEnd = DateTime.now();

  var userPermissions = {};

  var GlobalAddEventPermission = GlobalPermissions().addEventToCalendar;

  List iterateRules = [];
  int iterableRuleIndexActive = 0;

  String iterateTitle = 'newer';
  String iterateValue = '';

  var selectCalendarId;

  int _selectedIndex = 0;

  // var test = 'RRULE:FREQ=MONTHLY;BYDAY=1MO';



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
                      iterateTitle = iterateRules[iterableRuleIndexActive]['title'];
                      iterateValue = iterateRules[iterableRuleIndexActive]['value'];
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


  Future calendarNameDialog(){

    List<Calendar> selectedList = [];

    selectedCalendars.forEach((key, value) {
      selectedList.add(value);
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text("${selectedList[index].name}",
                            style: TextStyle(
                                fontSize: 15
                            ),),


                          Text(selectedList[index].typeEvents,
                            style: TextStyle(
                              fontSize: 10,
                            ),),
                        ],
                      ),

                      Column(
                        children: [

                          if (((GlobalAddEventPermission[autshUserData.role] > 0
                              && !userPermissions.containsKey(selectedList[index].id))
                              || (GlobalAddEventPermission[autshUserData.role] > 0
                                  && (userPermissions.containsKey(selectedList[index].id)
                                      && userPermissions[selectedList[index].id]['add'] != 0)))
                              && (selectedList[index].typeEvents != 'festival_shedule'
                                  && selectedList[index].typeEvents != 'tango_school')
                              || selectedList[index].creator == autshUserData.uid
                              || (autshUserData.role == 'su_admin'|| autshUserData.role == 'admin')
                          )
                            Checkbox(
                              value: selectedList[index].enable,
                              onChanged: (bool? newValue) {

                                calendarNameController.text = selectedList[index].name;
                                selectCalendarId = selectedList[index].id;
                                int x = 0;
                                selectedList.forEach((value) {
                                  selectedList[x].enable = false;
                                  x++;
                                });
                                selectedList[index].enable = newValue!;

                                setState(() {
                                });

                                Navigator.of(context).pop();

                              })
                          else 
                            Icon(Icons.do_disturb_alt_outlined, color: Colors.red,),
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


  Future recurenceDialog(){


    return  showDialog(
      context: context,
      builder: (_) =>  Dialog(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.repeatRules, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blueAccent),),
              ListView.separated(
                itemCount: iterateRules.length,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text("${iterateRules[index]['title']}",
                            style: TextStyle(
                                fontSize: 15
                            ),),


                          if (autshUserData.role == 'su_admin')
                            Text(iterateRules[index]['value'],
                              style: TextStyle(
                                fontSize: 10,
                              ),),
                        ],
                      ),

                      Column(
                        children: [
                          Checkbox(
                              value: iterateRules[index]['checked'],
                              onChanged: (bool? newValue) {

                                iterateRules[iterableRuleIndexActive]['checked']= false;
                                iterableRuleIndexActive = index;
                                iterateTitle = iterateRules[iterableRuleIndexActive]['title'];
                                iterateValue = iterateRules[iterableRuleIndexActive]['value'];
                                iterateRules[index]['checked'] = newValue!;

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



  Future<void> showTimeDialog(timeCommand) async {
    final TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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


  @override
  void initState() {
    super.initState();
    initTimezone();
    getUserPermissions();
  }


  @override
  Widget build(BuildContext context) {

    iterateTitle = AppLocalizations.of(context)!.newer;
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(AppLocalizations.of(context)!.createEventTitle),
          ),
          actions: [

            IconButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                icon: Icon(Icons.arrow_back),
            )

          ],
        ),
        body: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Form(
            key: _form,
            child: ListView(
              children: [

                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded (
                      child: GestureDetector(
                        onTap: () {
                          calendarNameDialog();
                        },
                        child: TextFormField(
                          enabled: false,
                          controller: calendarNameController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.selectedCalendar,
                            disabledBorder: OutlineInputBorder(),
                            hintText: AppLocalizations.of(context)!.selectedCalendar,
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded (
                      child: GestureDetector(
                        onTap: () => dateDialog(dateStart, 'start'),
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
                        onTap: () => dateDialog(dateStart, 'end'),
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${AppLocalizations.of(context)!.repeat}: $iterateTitle"),

                    const SizedBox(width: 20.0),

                    ElevatedButton(
                      onPressed: () {
                        recurenceDialog();
                      }, child: Text(AppLocalizations.of(context)!.rules,
                      style: TextStyle(
                          fontSize: 20
                      ),),),
                  ],
                ),


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
                      addEvent();
                    } else {
                      shortMessage(context, "error form field", 2);
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context)!.submit,
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
                icon: Icon(Icons.refresh, size: 0,),
                label: ''
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
        'calendars': [selectCalendarId],
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
          },
          'recurrence': [iterateValue]
        }
      };


      eventTitleController.text = '';
      iterateTitle = 'newer';
      iterateValue = '';
      eventTitleController.text = '';
      eventDescriptionController.text = '';

      print(requestTokenData['event']);

      CalendarRepository().apiAddEvent(requestTokenData).then((request) {

        if (request.containsKey('errorMessage')) {
          debugPrint("error message - ${request['errorMessage']}");
          shortMessage(context, "error - ${request['errorMessage']['error']['message']}", 2);
        } else {

          var eventPermission = {
            'eventId': request['data'][0]['eventId'],
            'userUid': autshUserData.uid,
            'add': 1,
            'redact': 1,
            'delete': 1,
            'updatedDt':  DateTime.now(),
            'changeUserId': autshUserData.uid
          };
          usersRepository().setUserEventPermissions(eventPermission);

          shortMessage(context, "event creaded", 2);
          print(request);

          setState(() {

          });

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

        break;
    }

  }

}

