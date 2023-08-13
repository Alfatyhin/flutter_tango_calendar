import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/UserData.dart';
import '../repositories/users/users_reposirory.dart';
import '../AppTools.dart';


late final FirebaseApp app;
late final FirebaseAuth auth;

class About extends StatefulWidget {
  const About({Key? key}) : super(key: key);

  @override
  _AboutState createState() => _AboutState();
}


Map<String, String> localizedValues = {
  'en': """Application for viewing and publishing tango events.
The main purpose of the application is to connect organizers and tangeros by giving a convenient tool for searching and publishing events.

In order to see the events, you need to load the list of available calendars on the calendar list page, select the ones you are interested in and update the events on the main page.
Viewing events for non-registered users is limited to 3 months ahead.
After registration, you can see events for 6 months ahead.

In order to add events, you need to submit an application after registration.
To apply for the role of the organizer, you must specify a profile on Facebook and save the data.
After confirming the application, you will be able to add events to existing calendars, create school schedule calendars, create festival schedule calendars, import events from your Facebook calendar.

Also, if you are not an organizer, but you have a desire to share interesting events, you can apply for the role of a volunteer, and after confirmation you will be able to import events from your Facebook calendar.

In order to import from your Facebook calendar, you need to go to your events / all / in the web version of Facebook, find the button add to calendar at the top right and copy the link of this button. Then save this link in the application in the profile or on the "facebook events" page (this link is stored only in the memory of your device for the privacy of your data and is deleted when you clear the application data or delete the application itself)

The application administration reserves the right to block access to the ability to add events or revoke the role if the added events do not relate to tango or are spam. """,

  'uk': """Додаток для перегляду та публікацій танго подій.
Головна мета програми, з'єднати організаторів та тангерів давши зручний інструмент пошуку та публікації заходів.

Для того, щоб побачити події, потрібно завантажити список доступних календарів на сторінці список календарів, вибрати ті що вам цікаві і оновити події на головній сторінці.
Перегляд подій для незареєстрованих користувачів обмежений 3 меци вперед.
Після реєстрації ви можете бачити події на 6 місяців.

Для того, щоб додавати події, потрібно подати заявку після реєстрації.
Для подання заявки на роль організатора необхідно вказати профіль у фейсбукеї зберегти дані.
Після підтвердження заявки Ви зможете додавати події до існуючих календарів, створювати календарі розкладів школи, створювати календарі розкладів фестивалів, робити імпорт подій зі свого календаря на фейсбуці.

Також якщо ви не організатор, але ви маєте бажання поділитися цікавими подіями, ви можете подати заявку на роль волонтера, і після підтвердження зможете робити іморт подій зі свого календаря на фейсбуці.

Для того, щоб робити імпорт зі свого календаря на фейсбуці, необхідно у веб версії фейсбуку зайти у свої заходи / все / праворуч вгорі знайти кнопку додати календар і скопіювати посилання цієї кнопки. Потім зберегти це посилання в програмі у профілі або на сторінці "події фейсбука" (дане посилання з метою конфіденційності ваших даних зберігається тільки в пам'яті вашого пристрою і видаляється при очищенні даних програми або видаленні самої програми)

Адміністрація програми залишає за собою право заблокувати доступ до можливості додавати події або відкликати роль у випадку, якщо події, що додаються, не відносяться до танго або є спамом.""",
};

class _AboutState extends State<About> {

  var lang = 'en';

  var _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  String? about() {
    if (lang == 'uk') {
      return localizedValues[lang];
    } else {
      return localizedValues['en'];
    }
  }

  @override
  Widget build(BuildContext context) {

    lang = Localizations.localeOf(context).toString();

    String? aboutText = about();

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('About/Contacts'),
          ),
          actions: [
            // IconButton(
            //   icon: Icon(Icons.menu),
            //   onPressed: _menuOpen,
            // )
          ],
        ),
        body: Container(
          margin: EdgeInsets.all(20),
          child: ListView(
            children: [
              Row (
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('About Tango Calendar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ],
              ),


              const SizedBox(height: 20),
              Text(aboutText!,
                style: TextStyle(
                  fontSize: 20
                ),
              ),

              const SizedBox(height: 20),
              TextButton(onPressed: () {
                Uri url = Uri.parse("https://tango-calendar.it-alex.net.ua/app/privacy-policy");
                _launchUrl(url);
              },
                child: Text('Privacy Policy', style: TextStyle(
                    fontSize: 20,
                    color: Colors.blue
                ),),
              ),

            ],
          ),
        ),

        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'home',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 0,),
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


  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  void _onItemTapped(int index) async {
    switch (index) {
      case 0:
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
    }
  }

}

