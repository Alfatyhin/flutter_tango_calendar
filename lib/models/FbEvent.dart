
import 'package:tango_calendar/models/Event.dart';

class FbEvent extends Event {
  FbEvent(super.eventId, super.name, super.description, super.location, super.timeUse, super.dateStart, super.timeStart, super.dateEnd, super.timeEnd, super.update, super.creatorEmail, super.creatorName, super.organizerEmail, super.organizerName);

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

}