import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/UserData.dart';
import '../repositories/users/users_reposirory.dart';
import '../AppTools.dart';


late final FirebaseApp app;
late final FirebaseAuth auth;

class UsersList extends StatefulWidget {
  const UsersList({Key? key}) : super(key: key);

  @override
  _UsersListState createState() => _UsersListState();
}


class _UsersListState extends State<UsersList> {

  List users = [];

  void initUsers() async {
    usersRepository().getUsers().then((value){
      users = value;
      setState(() {
      });
    });
  }


  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    initUsers();
  }


  void _userOpen(UserData data) {

    userRole = data.role;

    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
              appBar: AppBar(title: Text('event data'),),
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
                    Text('select role',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.black
                      ),
                    ),
                    UserRoleList(),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: () {
                      _changeRole(data.uid);
                      // Navigator.pop(context);
                    }, child: Text('change role',
                      style: TextStyle(
                          fontSize: 20
                      ),),),
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
          print('test - ${value}');
      initUsers();
      shortMessage(context as BuildContext, value as String, 2);
    });
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
            child: Text('Users'),
          ),
          actions: [
            // IconButton(
            //   icon: Icon(Icons.menu),
            //   onPressed: _menuOpen,
            // )
          ],
        ),
        body: ListView.builder(
          itemCount: users.length,
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
              child: ListTile(
                onTap: () => _userOpen(users[index]),
                title: Row(
                  textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(users[index].name, style: TextStyle(
                            fontWeight: FontWeight.w600
                        ),),
                        Text(users[index].email),
                      ],
                    )
                  ],
                ),
                subtitle: Text(users[index].role),
              ),
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
        initUsers();

        break;
    }

  }

}

