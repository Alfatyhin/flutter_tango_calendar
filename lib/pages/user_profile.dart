import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tango_calendar/repositories/localRepository.dart';

import '../models/Calendar.dart';
import '../models/UserData.dart';
import '../repositories/calendar/calendar_repository.dart';
import '../repositories/users/users_reposirory.dart';
import '../AppTools.dart';


late final FirebaseApp app;
late final FirebaseAuth auth;

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  _UserProfileState createState() => _UserProfileState();
}


class _UserProfileState extends State<UserProfile> {

  TextEditingController fbProfileController = TextEditingController();
  var userUid;
  var userData;
  var CalendarPermEventAdd = GlobalPermissions().addEventToCalendar;
  var CalendarPermEventRedact = GlobalPermissions().redactEventToCalendar;
  var CalendarPermEventDelete = GlobalPermissions().deleteEventToCalendar;
  List selectedCalendars = [];
  var CalendarStatmentRules = EventTypes().CalendarStatmentRules;
  Map userCalendarsPermissions = {};

  int _selectedIndex = 0;

  void setUserData(userUid) {

    debugPrint("-------setUserData-------");

    CalendarRepository().getLocalDataJson('selectedCalendars').then((selectedCalendarsJson) {

      CalendarRepository().getLocalDataJson('calendars').then((calendarsJson) {

        var selectedlist = [];
        var selectedData = [];
        if (selectedCalendarsJson != '') {
          selectedData = json.decode(selectedCalendarsJson as String);
        }
        if (selectedData.length > 0) {

          if (calendarsJson != '') {
            List calendarsData = json.decode(calendarsJson as String);

            debugPrint("-------selectedCalendars-------");
            debugPrint("autshUserData.role - ${autshUserData.role}");

            calendarsData.forEach((value) {
              var calendar = Calendar.fromLocalData(value);

              if (selectedData.contains(calendar.id)) {
                var typeEvents = calendar.typeEvents;

                debugPrint("typeEvents - $typeEvents");
                debugPrint("CalendarStatmentRules - ${CalendarStatmentRules[autshUserData.role][typeEvents]}");
                debugPrint("calendar.creator - ${calendar.creator}");

                if (CalendarStatmentRules[autshUserData.role][typeEvents] > 0
                    || calendar.creator == autshUserData.uid) {
                  calendar.enable = false;
                  selectedlist.add(calendar);

                  debugPrint("calendar add - ${calendar.name}");
                } else {

                  debugPrint("calendar not add - ${calendar.name}");
                }
              }

            });

            debugPrint("${selectedData.length} / ${selectedlist.length}");

            selectedCalendars = selectedlist;
            debugPrint("----------------------");

          }
        }

      });

    });


    usersRepository().getUserDataByUid(userUid).then((value) {
      userData = value as UserData;
      fbProfileController.text = userData.fbProfile;

      setState(() {});

    });
  }

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    var uid = ModalRoute.of(context)?.settings.arguments;

    return Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('Profile'),
          ),
          actions: [
            // IconButton(
            //   icon: Icon(Icons.menu),
            //   onPressed: _menuOpen,
            // )
          ],
        ),
        body: _body(uid),

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

  Widget _body(uid) {
    userUid = uid;
    // setUserData(userUid);
    if (userData == null) {
      setUserData(userUid);

    } else {
      userRole = userData.role;
      return
        Container (
          margin: EdgeInsets.only(top: 20.0, left: 10.0, right: 10.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                  child:  SelectableText("${userData.name}",
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w600
                    ),
                  )
              ),

              const SizedBox(height: 8.0),

              Center(
                child:  SelectableText("${userData.email}",
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 20),
                ),
              ),


              const SizedBox(height: 10.0),
              TextFormField(
                controller: fbProfileController,
                decoration: const InputDecoration(
                  hintText: 'Enter your Facebook profile',
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              ElevatedButton(onPressed: () {
                _changeFbUrl();
              }, child: Text('change profile fb url',
                style: TextStyle(
                    fontSize: 20
                ),),),

              _userLoleChange(),


              const SizedBox(height: 20),

              if (autshUserData.role != 'admin' && autshUserData.role != 'su_admin')
              ElevatedButton(onPressed: () {
                _calendarsStatmentOpen();
              }, child: Text('calendar permissins',
                style: TextStyle(
                    fontSize: 20
                ),),),

              const SizedBox(height: 20),
            ],
          ),
        );
    }
    return Text('await');
  }

  void _calendarsStatmentOpen() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
              appBar: AppBar(title: Text('Calendars permissions'),),
              body: _calendarsAdd()
          );
        })
    );
  }

  Widget _userLoleChange() {

    if (userData.fbProfile != '') {
      return ListView(
        shrinkWrap: true,
        children: [

          const SizedBox(height: 8.0),


          if (autshUserData.role != 'admin' && autshUserData.role != 'su_admin')

            Text('access level',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.black
              ),
            ),

          if (autshUserData.role != 'admin' && autshUserData.role != 'su_admin')
          UserRoleList(),

          if (autshUserData.role == 'admin' || autshUserData.role == 'su_admin')
            Text('access level <<${autshUserData.role}>>',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.black
              ),
            ),

          const SizedBox(height: 20),

          if (autshUserData.role != 'admin' && autshUserData.role != 'su_admin')
          ElevatedButton(onPressed: () {
            _changeRoleStatment(userData.uid);
          }, child: Text('statement',
            style: TextStyle(
                fontSize: 20
            ),),),
        ],
      );
    }
    return ListView(
      shrinkWrap: true,
      children: [

        const SizedBox(height: 8.0),

        Text('access level ${userData.role}',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.black
          ),
        ),
      ],
    );


  }

  Widget _calendarsAdd() {

    if (userCalendarsPermissions.length == 0) {
      CalendarRepository().getUserCalendarsPermissions(userData.uid).then((value) {
        userCalendarsPermissions = value;
        _calendarsAdd();
      });
    } else {

      int x = 0;
      selectedCalendars.forEach((value) {
        if (userCalendarsPermissions.containsKey(value.id)) {
          value.enable = true;
          selectedCalendars[x] = value;
        }
      });

    }


    if (CalendarPermEventAdd[autshUserData.role] > 0) {
      return ListView(
        // shrinkWrap: true,
        children: [
          ListView.separated(
            shrinkWrap: true,
            itemCount: selectedCalendars.length,
            padding: EdgeInsets.only(left: 20),
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
                  Column(
                    children: [
                      Text("${selectedCalendars[index].name}",
                        style: TextStyle(
                            fontSize: 16
                        ),),
                      Text("${selectedCalendars[index].typeEvents}",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700]
                        ),),
                    ],
                  ),
                  Column(
                    children: [

                      if (userCalendarsPermissions.containsKey(selectedCalendars[index].id)
                          || selectedCalendars[index].creator == autshUserData.uid)
                        Row(
                          children: [
                            if((userCalendarsPermissions.containsKey(selectedCalendars[index].id)
                                && userCalendarsPermissions[selectedCalendars[index].id]['add'] > 0)
                                || selectedCalendars[index].creator == autshUserData.uid)
                              Icon(Icons.add, color: Colors.green,)
                            else
                              Icon(Icons.add, color: Colors.grey,),


                            if((userCalendarsPermissions.containsKey(selectedCalendars[index].id)
                                && userCalendarsPermissions[selectedCalendars[index].id]['redact'] > 0
                                && CalendarPermEventRedact[userData.role] > 1)
                                || selectedCalendars[index].creator == autshUserData.uid)
                              Icon(Icons.app_registration, color: Colors.green,)
                            else if(userCalendarsPermissions.containsKey(selectedCalendars[index].id)
                                && userCalendarsPermissions[selectedCalendars[index].id]['redact'] > 0
                                && CalendarPermEventRedact[userData.role] == 1)
                              Icon(Icons.app_registration, color: Colors.blue,)
                            else
                              Icon(Icons.app_registration, color: Colors.grey,),


                            if((userCalendarsPermissions.containsKey(selectedCalendars[index].id)
                                && userCalendarsPermissions[selectedCalendars[index].id]['delete'] > 0
                                && CalendarPermEventDelete[userData.role] > 1)
                                || selectedCalendars[index].creator == autshUserData.uid)
                              Icon(Icons.delete, color: Colors.green,)
                            else if (userCalendarsPermissions.containsKey(selectedCalendars[index].id)
                                && userCalendarsPermissions[selectedCalendars[index].id]['delete'] > 0
                                && CalendarPermEventDelete[userData.role] == 1)
                              Icon(Icons.delete, color: Colors.blue,)
                            else
                              Icon(Icons.delete, color: Colors.grey,),

                            if (selectedCalendars[index].creator != autshUserData.uid)
                            Checkbox(
                                value: selectedCalendars[index].enable,
                                onChanged: (bool? newValue) {
                                  selectedCalendars[index].enable = newValue!;
                                  setState(() {
                                  });

                                  Navigator.pop(context);
                                  _calendarsStatmentOpen();
                                })
                          ],
                        )
                      else
                        Checkbox(
                            value: selectedCalendars[index].enable,
                            onChanged: (bool? newValue) {
                              selectedCalendars[index].enable = newValue!;
                              setState(() {
                              });

                              Navigator.pop(context);
                              _calendarsStatmentOpen();
                            })
                    ],
                  ),

                ],
              );
            },
          ),

          const SizedBox(height: 20),

          ElevatedButton(onPressed: () {
            _calendarsStatments(userData.uid);
          }, child: Text('statement to calendars',
            style: TextStyle(
                fontSize: 20
            ),),),
        ],
      );
    }
    return Center(child: Text('not permisions to calendars', style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 20
    ),));
  }

  Future<void> _changeRoleStatment(String uid) async {
    if (autshUserData.role != userRole) {
      var date = DateTime.now();
      var data = {
        "userUid": uid,
        "type": 'role',
        "value": userRole,
        "status": 'new',
        "createdDt": date,
        "updatedDt": date,
      };
      usersRepository().statementsAdd(data);
      shortMessage(context as BuildContext, 'statement send', 2);
      userRole = userData.role;
      setUserData(userUid);
    }
  }

  Future<void> _calendarsStatments(String uid) async {
    var date = DateTime.now();
    var selectedList = [];

    print('start');
    selectedCalendars.forEach((element) {
      if (element.enable) {
        print(element.name);
        selectedList.add(element.id);
      }
    });

    // if (selectedList.length > 0) {
    //   var data = {
    //     "userUid": uid,
    //     "type": 'calendars',
    //     "value": selectedList,
    //     "status": 'new',
    //     "createdDt": date,
    //     "updatedDt": date,
    //   };
    //   usersRepository().statementsAdd(data);
    //   shortMessage(context as BuildContext, 'statement send', 2);
    // }

  }

  Future<void> _changeFbUrl() async {

    await usersRepository().changeUserData(userUid, 'fbProfile', fbProfileController.text)
        .then((value) {
      setUserData(userUid);
      shortMessage(context as BuildContext, value as String, 2);
    });

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
        CalendarRepository().updateCalendarsData().then((value) {

          setUserData(userUid);
        });

        break;
    }

  }

}

