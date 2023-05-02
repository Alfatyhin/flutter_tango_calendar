import 'dart:collection';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/Event.dart';
import '../repositories/calendar/calendar_repository.dart';
import '../utils.dart';


class StartPage extends StatefulWidget {
  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {

  var key = DateTime.now();
  var value = Event('1', 'test event', 'нет событий', 'test event', 0, 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'test event', 'test event');
  var kEvents;
  int _selectedIndex = 0;


  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  late Map<DateTime, List<Event>> kEventSource;

  @override
  void initState() {
    super.initState();

    ///  без событий календарь валится
    kEventSource = {this.key: [value]};
    /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
    kEvents = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(kEventSource);
    //////////////////////////////////

    ///  загрузка событий из локального хранилища
    setlocaleJsonData();

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));

  }

  void _menuOpen() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: Text('Меню'),),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);
                }, child: Text('Календари событий',
                  style: TextStyle(
                      fontSize: 20
                  ),),),
                ElevatedButton(onPressed: () async {
                  await CalendarRepository().clearLocalDataJson('eventsJson');
                  setState(() {
                    kEventSource = {this.key: [value]};
                    /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
                    kEvents = LinkedHashMap<DateTime, List<Event>>(
                      equals: isSameDay,
                      hashCode: getHashCode,
                    )..addAll(kEventSource);

                    _selectedEvents.value = _getEventsForDay(_selectedDay!);
                  });
                }, child: Text('очистить список событий',
                  style: TextStyle(
                      fontSize: 20
                  ),))
              ],
            ),
          );
        })
    );
  }

  void _eventOpen(Event event) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: Text('event data'),),
            body:  Center(
                child: Container (
                  padding: EdgeInsets.only(top:25, left:10, right:10),
                  child:  Column(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    // mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${event.name}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600
                          ),
                          softWrap: true
                      ),
                      Text("",),
                      Text("${event.timePeriod()}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 20),
                          softWrap: true
                      ),
                      Text("",),
                      Text("${event.locationString()}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 15),
                          softWrap: true
                      ),
                      Text("",),
                      Text("${event.descriptionString()}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 20),
                          softWrap: true
                      ),
                      Text("",),
                      Text("${event.organizerName}",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 20),
                          softWrap: true
                      ),
                    ],
                  ),
                )

            ),
          );
        })
    );
  }


  @override
  Future<void> setlocaleJsonData() async {
    // CalendarRepository().setLocalDataJson('test', 'test 1');

    var oldJson = await CalendarRepository().getLocalDataJson('eventsJson');
    if (oldJson != '') {

      var data = json.decode(oldJson as String);
      kEventSource = CalendarRepository().getKeventToDataMap(data) as Map<DateTime, List<Event>>;

      /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
      kEvents = LinkedHashMap<DateTime, List<Event>>(
        equals: isSameDay,
        hashCode: getHashCode,
      )..addAll(kEventSource);
      setState(() {});
      _selectedEvents.value = _getEventsForDay(_selectedDay!);

    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {

    // Implementation example
    return kEvents[day] ?? [];
  }

  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    // Implementation example
    final days = daysInRange(start, end);

    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // `start` or `end` could be null
    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Tango Calendar'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: _menuOpen,
          )
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            locale: kLang,
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarFormat: _calendarFormat,
            rangeSelectionMode: _rangeSelectionMode,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              // Use `CalendarStyle` to customize the UI
              outsideDaysVisible: false,
            ),
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
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
                        onTap: () => _eventOpen(value[index]),
                        title: Row(
                          textDirection: TextDirection.ltr,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(value[index].name),
                                Text(value[index].timePeriod()),
                              ],
                            )
                          ],
                        ),
                        subtitle: Text('${value[index].locationString()}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'calendars',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete),
            label: 'clear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.update),
            label: 'update',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightBlueAccent[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Future<void> _onItemTapped(int index) async {
    switch (index) {
      case 0:
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(context, '/calendars', (route) => false);
        break;
      case 1:
        await CalendarRepository().clearLocalDataJson('eventsJson');
        setState(() {
          kEventSource = {this.key: [value]};
          /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
          kEvents = LinkedHashMap<DateTime, List<Event>>(
            equals: isSameDay,
            hashCode: getHashCode,
          )..addAll(kEventSource);

          _selectedEvents.value = _getEventsForDay(_selectedDay!);
          _selectedIndex = index;
        });
        break;
      case 2:
        kEvents = await CalendarRepository().getEventsList();
        setState(() {
          _selectedIndex = index;
        });
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
        break;
    }
  }
}
