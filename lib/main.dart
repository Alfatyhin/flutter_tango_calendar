import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tango_calendar/pages/user_profile.dart';
import 'pages/calendars.dart';
import 'pages/start_page.dart';
import 'pages/fb_events.dart';
import 'pages/register_user.dart';
import 'pages/login_user.dart';
import 'pages/users.dart';
import 'pages/statements.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'TableCalendar Example',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
              fontSize: 25,
              color: Colors.white,
              fontFamily: 'Frederic'
          ),
        ),
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) =>StartPage(),
        '/calendars': (context)  => const CalendarsPage(),
        '/fb_events': (context)  => const FbEvents(),
        '/register_user': (context)  => const RegisterUser(),
        '/login_user': (context)  => const LoginUser(),
        '/users': (context)  => const UsersList(),
        '/user_profile': (context)  => const UserProfile(),
        '/statements': (context)  => const StatementsList(),
      },
    );
  }
}
