import 'package:flutter/material.dart';
import '../AppTools.dart';
import '../repositories/users/users_reposirory.dart';


class EventSettings extends StatefulWidget {
  const EventSettings({Key? key}) : super(key: key);

  @override
  _EventSettingsState createState() => _EventSettingsState();
}


class _EventSettingsState extends State<EventSettings> {


  TextEditingController fbOrgNameController = TextEditingController();
  int _selectedIndex = 0;

  Map importRules = {
    'name': true,
    'location': false,
    'description': true
  };


  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }


  Future<void> _addFbOrgName() async {

    var applicateData = {
      'eventId': openEvent.eventId,
      'calId': openEvent.calendarId,
      'fbOrgName': fbOrgNameController.text,
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

        break;
    }

  }



}

