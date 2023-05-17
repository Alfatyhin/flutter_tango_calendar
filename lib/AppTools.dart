import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tango_calendar/repositories/users/users_reposirory.dart';
import 'package:tango_calendar/utils.dart';
import 'package:crypto/crypto.dart';

import 'models/UserData.dart';

class EventTypes {
  List eventTypes = ['festyval', 'milonga', 'practice', 'lessen sсhool', 'master class'];
  Map calendarCreatedRules = {
    'user': {},
    'volunteer': {},
    'organizer': {
      'festyval_shedule': 1,
      'festyvals world': 0,
      'master_classes': 0,
      'festyvals': 0,
      'milongas': 0,
      'practices': 0,
      'tango_sсhool': 1,
    },
    'admin': {
      'festyval_shedule': 1,
      'festyvals world': 0,
      'master_classes': 1,
      'festyvals': 1,
      'milongas': 1,
      'practices': 1,
      'tango_sсhool': 1,
    },
    'su_admin': {
      'festyval_shedule': 1,
      'festyvals world': 0,
      'master_classes': 1,
      'festyvals': 1,
      'milongas': 1,
      'practices': 1,
      'tango_sсhool': 1,
    },
  };

  // 0 - доступно  для создателя календаря
  // 1 - может подать заявку
  Map CalendarStatmentRules = {
    'user': {},
    'volunteer': {
      'festyval_shedule': 0,
      'festyvals world': 1,
      'master_classes': 1,
      'festyvals': 1,
      'milongas': 1,
      'practices': 1,
      'tango_sсhool': 0,},
    'organizer': {
      'festyval_shedule': 0,
      'festyvals world': 1,
      'master_classes': 1,
      'festyvals': 1,
      'milongas': 1,
      'practices': 1,
      'tango_sсhool': 0,
    },
  };
}

class CalendarTypes {
  List calendarTypes = [
    'festyval_shedule',
    'festyvals world',
    'master_classes',
    'festyvals',
    'milongas',
    'practices',
    'tango_sсhool',
  ];
}

class GlobalPermissions {
  // 1 - festyval shedule, lessens sсhool
  // 2 - festyval shedule, lessens sсhool, milongas city, practices city, festyvals city
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
  var date = DateTime.now();
  var signedToken = {};
  var dateString = '${date.year}-${NumFormat(date.month)}-${NumFormat(date.day)}-${NumFormat(date.hour)}';

  return usersRepository().getUserTokenByUid(autshUserData.uid).then((tokenData) {
    var string = utf8.encode('${tokenData['token']}-$dateString');
    var signed = md5.convert(string as List<int>);

    signedToken = {
      'tokenId': tokenData['tokenId'],
      'signed': signed
    };

    return signedToken;
  });


}