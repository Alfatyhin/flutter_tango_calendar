import 'package:flutter/material.dart';

class EventTypes {
  List eventTypes = ['festyval', 'milonga', 'practice', 'lessen sсhool', 'master class'];
  Map calendarCreatedRules = {
    'festyval': {
      'usertypes': {
        'su_admim': 2
      }
    }
  };
}

class CalendarTypes {
  List calendarTypes = [
    'festyval shedule',
    'festyvals world',
    'festyvals country',
    'festyvals city',
    'milongas city',
    'practices city',
    'lessens sсhool'
  ];
}

class GlobalPermissions {
  // 1 - festyval shedule, lessens sсhool
  // 2 - festyval shedule, lessens sсhool, milongas city, practices city, festyvals city
  // 3 - all CalendarTypes
  Map createCalendar = {
    'user': 0,
    'volгnteer': 0,
    'organaizer': 1,
    'admin': 2,
    'su_admin': 3
  };

  // 1 - проверка доступа по таблице доступов
  // 2 - all
  Map addEventToCalendar = {
    'user': 0,
    'volгnteer': 1,
    'organaizer': 1,
    'admin': 2,
    'su_admin': 2
  };

  // 1 - проверка доступа по таблице доступов
  // 2 - all
  Map redactEventToCalendar = {
    'user': 0,
    'volгnteer': 1,
    'organaizer': 1,
    'admin': 2,
    'su_admin': 2
  };

  // 1 - проверка доступа по таблице доступов
  // 2 - all
  Map deleteEventToCalendar = {
    'user': 0,
    'volгnteer': 1,
    'organaizer': 1,
    'admin': 2,
    'su_admin': 2
  };

  // предоставление доступав редактирования событий
  // 1 - могут давать доступ к своим календарям и событиям
  // 2 - all
  Map permissionsAdd = {
    'user': 0,
    'volгnteer': 0,
    'organaizer': 1,
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



class UserRoleList extends StatefulWidget {
  const UserRoleList({super.key});

  @override
  State<UserRoleList> createState() => _UserRoleListState();
}

var dropdownValueList;

class _UserRoleListState extends State<UserRoleList> {
  List<String> roleList = <String>['user', 'organizer', 'moderator', 'volunteer', 'admin', 'su_admin'];
  var dropdownValue;

  @override
  void initState() {
    super.initState();
    dropdownValue = dropdownValueList;
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