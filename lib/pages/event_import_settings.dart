import 'package:flutter/material.dart';
import '../AppTools.dart';
import '../repositories/users/users_reposirory.dart';


class EventSettings extends StatefulWidget {
  const EventSettings({Key? key}) : super(key: key);

  @override
  _EventSettingsState createState() => _EventSettingsState();
}


class _EventSettingsState extends State<EventSettings> {

  Map checkboxValue = {
    0: false,
    1: true
  };
  Map permissionsValue = {
    false: 0,
    true: 1
  };

  TextEditingController fbOrgNameController = TextEditingController();
  TextEditingController userUidController = TextEditingController();
  List fbOrgNames = [];
  int _selectedIndex = 0;
  Map eventFbImportRules = {};
  Map eventPermissions = {};
  String eventGUid = '';

  Map importRules = {
    'name': true,
    'location': false,
    'description': true
  };

  Map newPermissions = {
    'add': false,
    'delete': false,
    'redact': true
  };


  @override
  void initState() {
    super.initState();
    getEventImportRules();
  }

  Future<void> getEventImportRules() async {
    fbOrgNames = [];
    eventGUid = getEventGUid(openEvent.eventId);
    eventPermissions = await usersRepository().getEventsPermissions(eventGUid);
    var result = await usersRepository().getFbEventImportSettingsByEventId(eventGUid);


    if (result.length > 0) {
      eventFbImportRules = result[eventGUid];
      fbOrgNames = eventFbImportRules['fbOrgName'];
    }
    setState(() { });
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
            child: Text('Event Settings'),
          ),
          actions: [

          ],
        ),
        body: ListView(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              child: Center(
                child:   Text(
                  'fb import settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            Row(
              children: [
                Expanded(child: Text("GUID - $eventGUid"))
                ]
            ),

            if (fbOrgNames.length > 0)

              ListView.builder(
                  shrinkWrap: true,
                  itemCount: fbOrgNames.length,
                  itemBuilder: (BuildContext context, int index) {

                    return Container(
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                          child: Text("org name - ${fbOrgNames[index]}")
                      );
                  }
              ),


            Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              child:
              TextFormField(
                controller: fbOrgNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter organizer name',
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

            Container(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: Row(
                textDirection: TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("import name",
                    style: TextStyle(
                        fontSize: 15
                    ),),

                  Checkbox(
                      value: importRules['name'],
                      onChanged: (bool? newValue) {
                        importRules['name'] = newValue!;
                        setState(() {
                        });
                      })
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: Row(
                textDirection: TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("import location",
                    style: TextStyle(
                        fontSize: 15
                    ),),

                  Checkbox(
                      value: importRules['location'],
                      onChanged: (bool? newValue) {
                        importRules['location'] = newValue!;
                        setState(() {
                        });
                      })
                ],
              ),
            ),


            Container(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: Row(
                textDirection: TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("import description",
                    style: TextStyle(
                        fontSize: 15
                    ),),

                  Checkbox(
                      value: importRules['description'],
                      onChanged: (bool? newValue) {
                        importRules['description'] = newValue!;
                        setState(() {
                        });
                      })
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              child:  ElevatedButton(onPressed: () {
                _addFbOrgName();
              }, child: Text('save setting',
                style: TextStyle(
                    fontSize: 20
                ),),),
            ),

            Center(
                child:   Text("permissions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ),

            ListView.builder(
                shrinkWrap: true,
                itemCount: eventPermissions.length,
                itemBuilder: (context, index) {



                  return   Container(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                    child:  Column(
                      children: [
                        Text("user - ${eventPermissions[index]['userUid']}"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text("add permissions",
                                  style: TextStyle(
                                      fontSize: 15
                                  ),),

                                Checkbox(
                                    value: checkboxValue[eventPermissions[index]['add']],
                                    onChanged: (bool? newValue) {
                                      eventPermissions[index]['add'] = permissionsValue[newValue];
                                      setState(() {
                                      });
                                    })
                              ],
                            ),
                            Column(
                              children: [
                                Text("redact",
                                  style: TextStyle(
                                      fontSize: 15
                                  ),),

                                Checkbox(
                                    value: checkboxValue[eventPermissions[index]['redact']],
                                    onChanged: (bool? newValue) {
                                      eventPermissions[index]['redact'] = permissionsValue[newValue];
                                      setState(() {
                                      });
                                    })
                              ],
                            ),
                            Column(
                              children: [
                                Text("delete",
                                  style: TextStyle(
                                      fontSize: 15
                                  ),),

                                Checkbox(
                                    value: checkboxValue[eventPermissions[index]['delete']],
                                    onChanged: (bool? newValue) {
                                      eventPermissions[index]['delete'] = permissionsValue[newValue];
                                      setState(() {
                                      });
                                    })
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                }
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              child:
              TextFormField(
                controller: userUidController,
                decoration: const InputDecoration(
                  hintText: 'Enter user uid',
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

            Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              child:  Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text("add permissions",
                        style: TextStyle(
                            fontSize: 15
                        ),),

                      Checkbox(
                          value: newPermissions['add'],
                          onChanged: (bool? newValue) {
                            newPermissions['add'] = newValue!;
                            setState(() {
                            });
                          })
                    ],
                  ),
                  Column(
                    children: [
                      Text("redact",
                        style: TextStyle(
                            fontSize: 15
                        ),),

                      Checkbox(
                          value: newPermissions['redact'],
                          onChanged: (bool? newValue) {
                            newPermissions['redact'] = newValue!;
                            setState(() {
                            });
                          })
                    ],
                  ),
                  Column(
                    children: [
                      Text("delete",
                        style: TextStyle(
                            fontSize: 15
                        ),),

                      Checkbox(
                          value: newPermissions['delete'],
                          onChanged: (bool? newValue) {
                            newPermissions['delete'] = newValue!;
                            setState(() {
                            });
                          })
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              child:  ElevatedButton(onPressed: () {
                addNewPermissions();
              }, child: Text('add permissions',
                style: TextStyle(
                    fontSize: 20
                ),),),
            ),

            // Container(
            //     padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            //     child:  Center(
            //       child: Text(
            //         'export setting',
            //         style: TextStyle(
            //             fontSize: 20,
            //             fontWeight: FontWeight.w600,
            //             color: Colors.blue
            //         ),
            //       ),
            //     )
            // ),

            const SizedBox(height: 20),

          ],
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
      ),
    );
  }

  void addNewPermissions() {
    var add = 0;
    var redact = 0;
    var delete = 0;
    if (newPermissions['add'])
      add = 1;
    if (newPermissions['redact'])
      redact = 1;
    if (newPermissions['delete'])
      delete = 1;

    var eventPermission = {
      'eventId': eventGUid,
      'userUid': userUidController.text,
      'add': add,
      'redact': redact,
      'delete': delete,
      'updatedDt':  DateTime.now(),
      'changeUserId': autshUserData.uid
    };
    usersRepository().setUserEventPermissions(eventPermission);
  }

  List<Widget> fbOrgsList(orgs) {

    return  List<Widget>.generate(
        orgs.length,
            (int index) {
          return Column(
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(orgs[index],
                      style: TextStyle(
                          fontSize: 15
                      ),),
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
    );
  }

  Future<void> _addFbOrgName() async {

    var evenIdData = openEvent.eventId.split('_');

    if (fbOrgNames.length == 0) {
      fbOrgNames = [fbOrgNameController.text];
    } else {
      if (fbOrgNameController.text.length > 0 && !fbOrgNames.contains(fbOrgNameController.text)) {
        fbOrgNames.add(fbOrgNameController.text);
      }
    }

    var applicateData = {
      'eventId': evenIdData[0],
      'calId': openEvent.calendarId,
      'fbOrgName': fbOrgNames,
      'userUid': autshUserData.uid,
      'importRules': importRules,
      'autoImport': false
    };

    await usersRepository().addFbEventImportSettings(applicateData)
        .then((value) {
      Navigator.pop(context);
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      shortMessage(context, 'setting set', 2);
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

        getEventImportRules();
        break;
    }

  }



}

