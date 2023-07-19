import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../AppTools.dart';
import '../models/UserData.dart';
import '../repositories/users/users_reposirory.dart';

// TODO: додати вибір ролі при реестраціі


late final FirebaseApp app;
late final FirebaseAuth auth;

class RegisterUser extends StatefulWidget {
  const RegisterUser({Key? key}) : super(key: key);

  @override
  _RegisterUserState createState() => _RegisterUserState();
}


class _RegisterUserState extends State<RegisterUser> {

  void initFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    print('done init');
  }

  List<String> roleList = <String>['user', 'organizer', 'volunteer'];
  TextEditingController fbProfileController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String selectRole = 'user';
  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    initFirebase();
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
            child: Text('Registration'),
          ),
          actions: [
            // IconButton(
            //   icon: Icon(Icons.menu),
            //   onPressed: _menuOpen,
            // )
          ],
        ),
        body: Container(
          child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 10.0),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10.0),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) =>
                    value != null && value.isNotEmpty
                        ? null
                        : 'Required',
                  ),
                  const SizedBox(height: 10.0),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),


                  const SizedBox(height: 30.0),
                  Row(
                    children: [
                      Expanded(
                          child: Text('if you organiser or teacher, select role organiser.',
                          style: TextStyle(
                            fontSize: 18
                          ),
                          )
                      ),
                    ],
                  ),

                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      Expanded(
                          child: Text('if you not organiser or teacher & you want share event, select role volontuer.',
                            style: TextStyle(
                                fontSize: 18
                            ),
                          )),
                    ],
                  ),



                  const SizedBox(height: 20.0),
                  userRoleList(),

                  if (selectRole != 'user')
                   Row(
                     children: [
                       Column(
                         children: [
                           const SizedBox(height: 20.0),
                           Text('enter please you fb profile link'),
                           const SizedBox(height: 10.0),
                         ],
                       )
                     ],
                   ),

                  if (selectRole != 'user')

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


                  const SizedBox(height: 30.0),
                  Text('Check out the privacy policy.'
                      '\n''By continuing to register, you agree to its terms.',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.black
                    ),
                  ),


                  TextButton(onPressed: () {
                    Uri url = Uri.parse("https://tango-calendar.it-alex.net.ua/app/privacy-policy");
                    _launchUrl(url);
                  },
                    child: Text('Privacy Policy', style: TextStyle(
                        fontSize: 20,
                        color: Colors.blue
                    ),),
                  ),


                  const SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate will return true if the form is valid, or false if
                        // the form is invalid.
                        if (_formKey.currentState!.validate()) {
                          var name = nameController.text;
                          var email = emailController.text;
                          var password = passwordController.text;

                          _registerUser(email, password);

                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              )
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
              icon: Icon(Icons.numbers, color: Colors.white,),
              label: '',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.lightBlueAccent[800],
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  @override
  Widget userRoleList() {
    return DropdownButton<String>(
      value: selectRole,
      isExpanded: true,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(
          color: Colors.black,
          fontSize: 18
      ),
      underline: Container(
        height: 2,
        color: Colors.black26,
      ),
      onChanged: (String? value) {
        // This is called when the user selects an item.
        selectRole = value as String;
        setState(() {
          selectRole = value;
        });
      },
      items: roleList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: _listItem(value),
        );
      }).toList(),
    );
  }

  Widget _listItem(value) {
    if (value == selectRole) {
      return Text(value, style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600
      ),);
    } else {
      return Text(value);
    }
  }

  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }



  Future<void> _registerUser(email, password) async {
    try {

      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      FirebaseAuth.instance
          .authStateChanges()
          .listen((User? user) async {
        if (user != null) {
          await user.updateDisplayName(nameController.text);
          var userData = UserData(
            uid: user.uid,
            name: nameController.text,
            email: user.email,
            role: 'user',
            phone: '',
            fbProfile: fbProfileController.text,
            createdDt: user.metadata.creationTime,
            updatedDt: user.metadata.creationTime,
          );
          await usersRepository().addNewUser(userData);

          if (selectRole != 'user') {
            await _changeRoleStatment(user.uid);
          }
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      });

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }


  Future<void> _changeRoleStatment(String uid) async {

    var date = DateTime.now();
    var data = {
      "userUid": uid,
      "type": 'role',
      "value": selectRole,
      "status": 'new',
      "createdDt": date,
      "updatedDt": date,
    };
    usersRepository().statementsAdd(data);
    shortMessage(context as BuildContext, 'statement send', 2);

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
