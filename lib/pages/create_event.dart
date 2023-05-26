import 'package:flutter/material.dart';
import 'package:tango_calendar/models/Calendar.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../AppTools.dart';
import '../repositories/calendar/calendar_repository.dart';
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

  List iterateRules = [];
  int iterableRuleIndexActive = 0;

  String iterateTitle = 'newer';
  String iterateValue = '';

  var selectCalendarId;

  int _selectedIndex = 0;

  var test = 'RRULE:FREQ=MONTHLY;BYDAY=1MO';



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
                      child: Text('close')
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


  Future recurenceDialog(){

    print(iterateRules);


    return  showDialog(
      context: context,
      builder: (_) =>  Dialog(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

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



  Future<void> showTimeDialog(timeCommand) async {
    final TimeOfDay? result =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (result != null) {
      if (timeCommand == 'start') {
        timeStartStringController.text = result.format(context);
      } else {
        timeEndStringController.text = result.format(context);
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


  @override
  void initState() {
    super.initState();
    initTimezone();
  }


  @override
  Widget build(BuildContext context) {



    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Create Event'),
        ),
        actions: [

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
                        decoration: const InputDecoration(
                          labelText: 'selected calendar',
                          disabledBorder: OutlineInputBorder(),
                          hintText: 'Select Calendar',
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
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(),
                  hintText: 'Event Title',
                  labelText: 'Event Title',
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
                        decoration: const InputDecoration(
                          label: Text('dete start', style: TextStyle(
                            color: Colors.black
                          ),),
                          disabledBorder: OutlineInputBorder(),
                          hintText: 'Start date',
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
                        decoration: const InputDecoration(
                          label: Text('dete end', style: TextStyle(
                              color: Colors.black
                          ),),
                          disabledBorder: OutlineInputBorder(),
                          hintText: 'Start date',
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
                        decoration: const InputDecoration(
                          label: Text('time start', style: TextStyle(
                            color: Colors.black
                          ),),
                          disabledBorder: OutlineInputBorder(),
                          hintText: 'Time start',
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
                        decoration: const InputDecoration(
                          label: Text('time end', style: TextStyle(
                              color: Colors.black
                          ),),
                          disabledBorder: OutlineInputBorder(),
                          hintText: 'Time end',
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
                  Text("repeat: $iterateTitle"),

                  const SizedBox(width: 20.0),

                  ElevatedButton(
                    onPressed: () {
                    recurenceDialog();
                  }, child: Text('rules',
                    style: TextStyle(
                        fontSize: 20
                    ),),),
                ],
              ),


              const SizedBox(height: 20.0),
              TextFormField(
                controller: eventLocationnController,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(),
                  hintText: 'Event Location',
                  labelText: 'Event Location',
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
                      labelText: 'Event Description'
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  expands: true, // <-- SEE HERE
                ),
              ),

              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  addEvent();
                },
                child: const Text(
                  'Send',
                  style: TextStyle(fontSize: 24),
                ),
              ),


            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'home',
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
    );
  }

  void addEvent() {
    ApiSigned().then((signedData) {

      var dtStart = DateTime.parse("${dateStartStringController.text}T${timeStartStringController.text}").toUtc();
      var dtEnd = DateTime.parse("${dateEndStringController.text}T${timeEndStringController.text}").toUtc();

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
          'orgenizer': {
            'displayName': autshUserData.name,
            'email': autshUserData.email
          },
          'recurrence': [iterateValue]
        }
      };


      print(requestTokenData['event']);

      CalendarRepository().apiAddEvent(requestTokenData).then((request) {

        if (request.containsKey('errorMessage')) {
          debugPrint("error message - ${request['errorMessage']}");
          shortMessage(context, "error - ${request['errorMessage']['error']['message']}", 2);
        } else {
          debugPrint("response sugess");

          print(request);
          // setState(() {});

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
      monWeekTitle = 'last';
    }

    if (weekXm == 1) {
      monWeekTitle = 'first';
    } else if (weekXm == 2) {
      monWeekTitle = 'second';
    } else if (weekXm == 3) {
      monWeekTitle = 'third';
    } else if (weekXm == 4) {
      monWeekTitle = 'fourth';
    } else if (weekXm == 5) {
      monWeekTitle = 'fifth';
    }


    iterateRules = [
      {
        'title': 'newer',
        'value': '',
        'checked': false
      },
      {
        'title': 'weekly ewery $wDayText',
        'value': 'RRULE:FREQ=WEEKLY;BYDAY=$wDayText',
        'checked': false
      },
      {
        'title': 'monthly ewery $monWeekTitle $wDayText',
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

