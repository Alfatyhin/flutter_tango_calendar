// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/calendars.dart';
import 'pages/start_page.dart';
import 'pages/fb_events.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'TableCalendar Example',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
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
        '/calendars': (context)  => CalendarsPage(),
        '/fb_events': (context)  => FbEvents(),
      },
    );
  }
}
