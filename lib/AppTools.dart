import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tango_calendar/repositories/calendar/calendar_repository.dart';
import 'package:tango_calendar/repositories/users/users_reposirory.dart';
import 'package:crypto/crypto.dart';

import 'models/Calendar.dart';
import 'models/Event.dart';
import 'models/UserData.dart';


FirebaseFirestore db = FirebaseFirestore.instance;
var kEvents;
late Event openEvent;

var CalendarPermEventAdd = GlobalPermissions().addEventToCalendar;
var CalendarPermEventRedact = GlobalPermissions().redactEventToCalendar;
var CalendarPermEventDelete = GlobalPermissions().deleteEventToCalendar;

Map userCalendarsPermissions = {};
Map selectedCalendars = {};

Map calendarsTypesMap = {
  'festivals': [],
  'master_classes': [],
  'milongas': [],
  'practices': [],
  'tango_school': [],
};
Map AllCalendars = {};

String backRout = '';

Map backCommand = {
  'comand': '',
  'argument': false
};


Future<void> calendarsMapped() async {

  calendarsTypesMap = {
    'festivals': [],
    'master_classes': [],
    'milongas': [],
    'practices': [],
    'tango_school': [],
  };
  AllCalendars = {};

  print('calendarsMapped');
  var calendarsJson = await CalendarRepository().getLocalDataJson('calendars');

  if (calendarsJson != '') {
    List calendarsData = json.decode(calendarsJson as String);

    calendarsData.forEach((value) {
      Calendar calendar = Calendar.fromLocalData(value);
      if (calendar.country != 'All') {
        calendarsTypesMap[calendar.typeEvents].add(calendar.id);
      } else {
        List events = [calendar.id];
        events.addAll(calendarsTypesMap[calendar.typeEvents]);
        calendarsTypesMap[calendar.typeEvents] = events;
      }
      AllCalendars[calendar.id] = calendar;
    });
  }
}

class EventTypes {
  List eventTypes = ['festyval', 'milonga', 'practice', 'lessons sсhool', 'master class'];


  // 0 - доступно  для создателя календаря
  // 1 - может подать заявку
  Map CalendarStatmentRules = {
    'user': {
      'festival_shedule': 0,
      'festivals world': 0,
      'master_classes': 0,
      'festivals': 0,
      'milongas': 0,
      'practices': 0,
      'tango_school': 0,
    },
    'volunteer': {
      'festival_shedule': 0,
      'festivals world': 1,
      'master_classes': 1,
      'festivals': 1,
      'milongas': 1,
      'practices': 1,
      'tango_school': 0,
    },
    'organizer': {
      'festival_shedule': 0,
      'festivals world': 1,
      'master_classes': 1,
      'festivals': 1,
      'milongas': 1,
      'practices': 1,
      'tango_school': 0,
    },
    'admin': {
      'festival_shedule': 0,
      'festivals world': 0,
      'master_classes': 1,
      'festivals': 1,
      'milongas': 1,
      'practices': 1,
      'tango_school': 0,
    },
    'su_admin': {
      'festival_shedule': 0,
      'festivals world': 0,
      'master_classes': 1,
      'festivals': 1,
      'milongas': 1,
      'practices': 1,
      'tango_school': 0,
    },
  };
}

class CalendarTypes {

  List calendarTypes = [
    'festival_shedule',
    'festivals world',
    'master_classes',
    'festivals',
    'milongas',
    'practices',
    'tango_school',
  ];

  Map<String, dynamic> calendarCreatedRules = {
    'user': {},
    'volunteer': {},
    'organizer': {
      'festival_shedule': 1,
      'festivals world': 0,
      'master_classes': 0,
      'festivals': 0,
      'milongas': 0,
      'practices': 0,
      'tango_school': 1,
    },
    'admin': {
      'festival_shedule': 1,
      'festivals world': 0,
      'master_classes': 1,
      'festivals': 1,
      'milongas': 1,
      'practices': 1,
      'tango_school': 1,
    },
    'su_admin': {
      'festival_shedule': 1,
      'festivals world': 0,
      'master_classes': 1,
      'festivals': 1,
      'milongas': 1,
      'practices': 1,
      'tango_school': 1,
    },
  };
}

class GlobalPermissions {
  // 1 - festyval shedule, lessens sсhool
  // 2 - festyval shedule, lessens sсhool, milongas city, practices city, festivals city
  // 3 - all CalendarTypes
  Map createCalendar = {
    'user': 0,
    'volunteer': 0,
    'organizer': 1,
    'admin': 2,
    'su_admin': 3
  };

  // 1 - разрешено
  // 2 - всегда
  Map addEventToCalendar = {
    'user': 0,
    'volunteer': 1,
    'organizer': 1,
    'admin': 2,
    'su_admin': 2
  };

  // 1 - только команде создателя события
  // 2 - всегда
  Map redactEventToCalendar = {
    'user': 0,
    'volunteer': 0,
    'organizer': 1,
    'admin': 2,
    'su_admin': 2
  };

  // 1 - только команде создателя события
  // 2 - всегда
  Map deleteEventToCalendar = {
    'user': 0,
    'volunteer': 0,
    'organizer': 1,
    'admin': 2,
    'su_admin': 2
  };

  // предоставление доступав редактирования событий
  // 1 - могут давать доступ к своим календарям и событиям
  // 2 - all
  Map permissionsAdd = {
    'user': 0,
    'volunteer': 0,
    'organizer': 1,
    'admin': 2,
    'su_admin': 2
  };

}

class shortMessage {

  shortMessage(BuildContext context, String text, int sec) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Center(
        child: Text(text),
      ),
      backgroundColor: Colors.blueAccent,
      duration: Duration(seconds: sec),
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.symmetric(
        horizontal: 8.0, // Inner padding for SnackBar content.
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    ));
  }
}

late UserData autshUserData;

class UserRoleList extends StatefulWidget {
  const UserRoleList({super.key});

  @override
  State<UserRoleList> createState() => _UserRoleListState();
}

var userRole;

class _UserRoleListState extends State<UserRoleList> {
  List<String> roleList = <String>['user', 'organizer', 'moderator', 'volunteer', 'admin', 'su_admin'];
  var dropdownValue;

  @override
  void initState() {
    super.initState();
    dropdownValue = userRole;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
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
        userRole = value;
        setState(() {
          dropdownValue = value!;
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
    if (value == dropdownValue) {
      return Text(value, style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600
      ),);
    } else {
      return Text(value);
    }
  }


}

Future<Map> ApiSigned() async {
  var signedToken = {};

  return CalendarRepository().getApiServerTimeSigned().then((dateString) {
    return usersRepository().getUserTokenByUid(autshUserData.uid).then((tokenData) {
      var string = utf8.encode('${tokenData['token']}-$dateString');
      var signed = md5.convert(string as List<int>);

      signedToken = {
        'tokenId': tokenData['tokenId'],
        'signed': signed
      };

      return signedToken;
    });
  });

}