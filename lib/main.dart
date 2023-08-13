import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/add_calendar.dart';
import 'pages/create_event.dart';
import 'pages/edit_event.dart';
import 'pages/event_import_settings.dart';
import 'pages/user_profile.dart';
import 'pages/calendars.dart';
import 'pages/start_page.dart';
import 'pages/fb_events.dart';
import 'pages/register_user.dart';
import 'pages/login_user.dart';
import 'pages/users.dart';
import 'pages/statements.dart';
import 'pages/about.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tango Calendar',
      // localizationsDelegates: [
      //   AppLocalizations.delegate,
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: [
      //   Locale('en'),
      //   Locale('uk'),
      // ],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
              fontSize: 20,
              color: Colors.white,
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
        '/event_settings': (context)  => const EventSettings(),
        '/create_event': (context)  => const CreateEvent(),
        '/edit_event': (context)  => const EditEvent(),
        '/add_calendar': (context)  => const AddCalendar(),
        '/about': (context)  => const About(),
      },
    );
  }
}
