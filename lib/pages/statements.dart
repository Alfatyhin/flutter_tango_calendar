import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/Calendar.dart';
import '../models/UserData.dart';
import '../repositories/calendar/calendar_repository.dart';
import '../repositories/users/users_reposirory.dart';
import '../AppTools.dart';


class StatementsList extends StatefulWidget {
  const StatementsList({Key? key}) : super(key: key);

  @override
  _StatementsListState createState() => _StatementsListState();
}


class _StatementsListState extends State<StatementsList> {

  List statementsNew = [];
  Map statmensUsersData = {};
  var selectedCalendars = [];
  var statmentOpenIndex;

  Map addEventToCalendar = GlobalPermissions().addEventToCalendar;
  Map redactEventToCalendar = GlobalPermissions().redactEventToCalendar;
  Map deleteEventToCalendar = GlobalPermissions().deleteEventToCalendar;


  void initData() async {

    statementsNew = [];

    usersRepository().getNewStatements().then((statements){

      if (statements.length > 0) {

        statementsNew = statements;
        statmensUsersData = {};
        List usersUds = [];
        statementsNew.forEach((element) {
          usersUds.add(element['userUid']);
        });

        usersRepository().getUsersDataByUids(usersUds).then((data) {

          data.forEach((userData) {
            statmensUsersData[userData.uid] = userData;
          });

          setState(() {});
        });
      }
    });
  }

  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    initData();
  }


  void _userStaitmensOpen(UserData data, statement) {
    userRole = data.role;


    if (statement['type'] == 'calendars' && selectedCalendars.length == 0) {
      CalendarRepository().getLocalDataJson('calendars').then((calendarsJson) {

        if (calendarsJson != '') {
          Map dataCalendars = json.decode(calendarsJson as String);

          Map calendarsData = dataCalendars['calendars'];

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

            if (statement['value'].contains(key)) {
              calendar.enable = true;
              selectedCalendars.add(calendar);
            }

            setState(() {
            });

            Navigator.pop(context);
            _userStaitmensOpen(data, statement);
          });

        }
      });


    }


    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
              appBar: AppBar(title: Text('statements data'),),
              body: Container (
                margin: EdgeInsets.only(top: 20.0, left: 10.0, right: 10.0),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Center(
                        child:  SelectableText("${data.name}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600
                          ),
                        )
                    ),
                    const SizedBox(height: 8.0),
                    Center(
                      child:  SelectableText("${data.email}",
                        textDirection: TextDirection.ltr,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text('role - ${data.role}',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.black
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    SelectableText("fb url - ${data.fbProfile}",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.black
                      ),
                    ),

                    const SizedBox(height: 8.0),

                    _calendarsAdd(data, statement),

                    if (selectedCalendars.length > 0)

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(onPressed: () {
                            _rejectStatement(statement['id']);
                          },
                            style: ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll<Color>(Colors.red.shade900),
                            ),
                            child: Text('reject',
                              style: TextStyle(
                                  fontSize: 15
                              ),),),

                          ElevatedButton(onPressed: () {
                            _confirmStatement(statement['id'], statement['type'], data.uid);
                            Navigator.pop(context);
                            statementsNew.removeAt(statmentOpenIndex);
                            setState(() {

                            });
                          },
                            style: ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll<Color>(Colors.green),
                            ),
                            child: Text('confirm',
                              style: TextStyle(
                                  fontSize: 15
                              ),),),
                        ],
                      )



                  ],
                ),
              )
          );
        })
    );
  }


  Widget _calendarsAdd(userData, statement) {

    var selectedList = selectedCalendars;

    return ListView(
      shrinkWrap: true,
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
                Text("${selectedCalendars[index].name} - ${selectedCalendars[index].typeEvents}",
                  style: TextStyle(
                      fontSize: 15
                  ),),
                Checkbox(
                    value: selectedCalendars[index].enable,
                    onChanged: (bool? newValue) {

                      selectedList[index].enable = newValue!;
                      selectedCalendars[index].enable = newValue!;
                      setState(() {
                      });

                      Navigator.pop(context);
                      _userStaitmensOpen(userData, statement);
                    })
              ],
            );
          },
        ),

      ],
    );

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Statements'),
        ),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.menu),
          //   onPressed: _menuOpen,
          // )
        ],
      ),
      body: ListView.builder(
        itemCount: statementsNew.length,
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
              child: _statmenListItem(index)
          );
        },
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

  Widget _statmenListItem(index) {
    var statement = statementsNew[index];
    var userKey = statement['userUid'];
    UserData userData = statmensUsersData[userKey];
    String info = '';

    if (statement['type'] == 'role') {
      info = 'change user role ${userData.role} to ${statement['value']}';
    }

    if (statement['type'] == 'calendars') {
      info = 'calendars permissions - push to confirm';
    }

    return   ListTile(
        onTap: () {
          statmentOpenIndex = index;
          _userStaitmensOpen(userData, statement);
        },
        title: Row(
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(userData.name, style: TextStyle(
                    fontWeight: FontWeight.w600
                ),),
                Text(info),
                Text(userData.email),
              ],
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            if (statement['type'] == 'role')

              ElevatedButton(onPressed: () {
                _rejectStatement(statement['id']);
              },
                style: ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll<Color>(Colors.red.shade900),
                ),
                child: Text('reject',
                  style: TextStyle(
                      fontSize: 15
                  ),),),


            if (statement['type'] == 'role')

              ElevatedButton(onPressed: () {
                userRole = statement['value'];
                _confirmStatement(statement['id'], statement['type'], userData.uid);
              },
                style: ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll<Color>(Colors.green),
                ),
                child: Text('confirm',
                  style: TextStyle(
                      fontSize: 15
                  ),),),

          ],
        )
    );
  }

  void _rejectStatement(id) {
    print(autshUserData.uid);

    var date = DateTime.now();
    var data = {
      'status': 'reject',
      'updatedDt': date,
      'changeUserId': autshUserData.uid
    };
    usersRepository().changeStatmentData(id, data).then((value) {
      initData();
      shortMessage(context as BuildContext, value as String, 2);
    });
  }

  void _confirmStatement(id, type, userUid) {

    var date = DateTime.now();

    if (type == 'role') {
      usersRepository().changeUserData(userUid, 'role', userRole)
          .then((value) {
      });

      if (userRole != 'user') {

        ApiSigned().then((signedData) {
          var requestTokenData = {
            'userUid': userUid,
            'userRole': userRole,
            'tokenId': signedData['tokenId'],
            'signed': '${signedData['signed']}',
          };

          CalendarRepository().getApiToken(requestTokenData).then((tokenData) {

            tokenData['userUid'] = userUid;
            usersRepository().setUserToken(tokenData);

          });

        });


      }


      var data = {
        'status': 'confirm',
        'updatedDt': date,
        'changeUserId': autshUserData.uid
      };
      usersRepository().changeStatmentData(id, data).then((value) {
        initData();
        shortMessage(context as BuildContext, value as String, 2);
      });
    }


    if (type == 'calendars') {

      selectedCalendars.forEach((calendar) {

        if (calendar.enable) {

          var calendarPermission = {
            'calId': calendar.id,
            'userUid': userUid,
            'add': addEventToCalendar[userRole],
            'redact': redactEventToCalendar[userRole],
            'delete': deleteEventToCalendar[userRole],
            'updatedDt': date,
            'changeUserId': autshUserData.uid
          };
          usersRepository().setCalendarsPermissions(calendarPermission);
        }

        var data = {
          'status': 'confirm',
          'updatedDt': date,
          'changeUserId': autshUserData.uid
        };
        usersRepository().changeStatmentData(id, data).then((value) {
          // initData();

          shortMessage(context as BuildContext, value as String, 2);
        });

      });
    }
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
        initData();

        break;
    }

  }

}

