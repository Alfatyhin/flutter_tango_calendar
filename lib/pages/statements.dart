import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/UserData.dart';
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

  void initData() async {

    statementsNew = [];

    setState(() {});
    usersRepository().getNewStatements().then((statements){

      if (statements.length > 0) {

        statementsNew = statements;
        statmensUsersData = {};
        List usersUds = [];
        statementsNew.forEach((element) {
          print(element);
          usersUds.add(element['userUid']);
        });

        usersRepository().getUsersDataByUids(usersUds).then((data) {

          data.forEach((userData) {
            statmensUsersData[userData.uid] = userData;
          });

          print(statmensUsersData);

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


  void _userOpen(UserData data) {

    userRole = data.role;

    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
              appBar: AppBar(title: Text('statements data'),),
              body: Container (
                margin: EdgeInsets.only(top: 20.0, left: 10.0, right: 10.0),
                child: ListView(
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
                  ],
                ),
              )
          );
        })
    );
  }

  Future<void> _changeRole(uid) async {
    await usersRepository().changeUserData(uid, 'role', userRole)
        .then((value) {
      initData();
      shortMessage(context as BuildContext, value as String, 2);
    });
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

    return   ListTile(
      onTap: () => _userOpen(userData),
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
    if (type == 'role') {
      usersRepository().changeUserData(userUid, 'role', userRole)
          .then((value) {
        initData();
      });
      var date = DateTime.now();
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

