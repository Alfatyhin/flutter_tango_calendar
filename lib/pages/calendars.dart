import 'package:flutter/material.dart';

import '../repositories/calendar/calendar_repository.dart';

class CalendarsPage extends StatefulWidget {
  const CalendarsPage({Key? key}) : super(key: key);

  @override
  _CalendarsPageState createState() => _CalendarsPageState();
}

class _CalendarsPageState extends State<CalendarsPage> {

  List calendarsList = [];


  void _menuOpen() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: Text('Меню'),),
            body: Column(
              children: [
                ElevatedButton(onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }, child: Text('на главную')),
                ElevatedButton(onPressed: () async {
                  await CalendarRepository().clearLocalDataJson('eventsJson');
                  setState(() {});
                }, child: Text('очистить список салендарей'))
              ],
            ),
          );
        })
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Список календарей'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: _menuOpen,
          )
        ],
      ),
      body: ListView.builder(
          itemCount: calendarsList.length,
          itemBuilder: (BuildContext context, int index) {
            return Dismissible(
              key: Key(calendarsList[index]),
              child: Card(
                child: ListTile(
                  title: Text(calendarsList[index]),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_sweep,
                      color: Colors.deepOrange,
                    ), onPressed: () {
                    setState(() {
                      calendarsList.removeAt(index);
                    });
                  },
                  ),
                ),
              ),
              onDismissed: (direction) {
                setState(() {
                  calendarsList.removeAt(index);
                });
              },
            );
          }
      ),
    );
  }
}


