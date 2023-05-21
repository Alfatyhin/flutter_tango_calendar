
import 'package:tango_calendar/models/Event.dart';

import '../utils.dart';

class FbEvent extends Event {
  FbEvent(
  super.eventId,
  super.name,
  super.description,
  super.location,
  super.timeUse,
  super.dateStart,
  super.timeStart,
  super.dateEnd,
  super.timeEnd,
  super.update,
  super.creatorEmail,
  super.creatorName,
  super.organizerEmail,
  super.organizerName,
  super.calendarId
  );

  var _importData;
  var url;
  var status;
  var importStatus;

  Map get importData => _importData;

  set importData(value) {
    _importData = value;
  }

  String timePeriod() {
    String string = 'весь день';
    if (timeUse != 0 ) {
      if (dateStart == dateEnd) {
        string = "$dateStart c $timeStart до $timeEnd";
      } else {
        string = "с $dateStart $timeStart по $dateEnd $timeEnd";
      }
    } else {
      if (dateStart != dateEnd) {
        string = "с $dateStart по $dateEnd";
      }
    }
    return string;
  }


  Map<String, Object> importToApi(){
    var start = {
      'date': "${dateStart}"
    };
    var end = {
      'date': "${dateEnd}"
    };

    if (timeUse != 0 ) {

      var dateTimeStart = DateTime.parse(_importData['dtstart'].dt);
      var timeStart = DateFormatTime(dateTimeStart);

      var dateTimeEnd = DateTime.parse(_importData['dtend'].dt);
      var timeEnd = DateFormatTime(dateTimeEnd);

      RegExp exp = RegExp("-");
      var statrTime = timeStart.replaceAll(exp, ":");
      var endTime = timeEnd.replaceAll(exp, ":");

      start = {
        'dateTime': "${dateStart}T${statrTime}:00-00:00"
      };
      end = {
        'dateTime': "${dateEnd}T${endTime}:00-00:00"
      };
    }

    return{
      "name": name,
      "location": this.locationString(),
      "description": this.descriptionString(),
      "start": start,
      "end": end,
      "source": {
        'title': 'Fb Import',
        'url': url
      }
    };
  }

}