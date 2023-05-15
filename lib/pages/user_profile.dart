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
  List selectedCalendars = [];

  int _selectedIndex = 0;

  void setUserData(userUid) {

    CalendarRepository().getLocalDataJson('selectedCalendars').then((selectedCalendarsJson) {

      CalendarRepository().getLocalDataJson('calendars').then((calendarsJson) {

        var selectedlist = [];
        var selectedData = [];
        if (selectedCalendarsJson != '') {
          selectedData = json.decode(selectedCalendarsJson as String);
          print(selectedData);
        }
        if (selectedData.length > 0) {

          if (calendarsJson != '') {
            Map data = json.decode(calendarsJson as String);

            Map calendarsData = data['calendars'];

            calendarsData.forEach((key, value) {
              var calendar = Calendar(
                  key,
                  value['name'],
                  value['description'],
                  value['type_events'],
                  value['country'],
                  value['city'],
                  value['source']
              );

              if (selectedData.contains(key)) {
                calendar.enable = true;
                selectedlist.add(calendar);
              }

            });

            selectedCalendars = selectedlist;
            setState(() {});

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
              }, child: Text('change fb url',
                style: TextStyle(
                    fontSize: 20
                ),),),

              _userLoleChange(),




              const SizedBox(height: 20),

             // _calendarsAdd(),

              const SizedBox(height: 20),
            ],
          ),
        );
    }
    return Text('await');
  }

  Widget _userLoleChange() {

    if (userData.fbProfile != '') {
      return ListView(
        shrinkWrap: true,
        children: [

          const SizedBox(height: 8.0),

          Text('access level',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black
            ),
          ),

          UserRoleList(),

          const SizedBox(height: 20),

          ElevatedButton(onPressed: () {
            _changeRole(userData.uid);
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
    if (CalendarPermEventAdd[userData.role] > 0) {
      return ListView(
        children: [
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
                  Checkbox(value: false, onChanged: (bool? newValue) {
                    print(selectedCalendars);
                    print(selectedCalendars[index]);
                    // setState(() {
                    //   selectedCalendars[index].enable = newValue!;
                    // });
                    // selectCalendar();
                  })
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          ElevatedButton(onPressed: () {
            _changeRole(userData.uid);
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

  Future<void> _changeRole(String uid) async {
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
        setUserData(userUid);

        break;
    }

  }

}

