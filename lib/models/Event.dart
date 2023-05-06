
class Event{
  final String eventId;
  final String name;
  final dynamic description;
  final dynamic location;
  final int timeUse;
  final String dateStart;
  final String timeStart;
  final String dateEnd;
  final String timeEnd;
  final String update;
  final String creatorEmail;
  final dynamic creatorName;
  final String organizerEmail;
  final dynamic organizerName;
  var calendar_id;

  Event(this.eventId, this.name, this.description, this.location, this.timeUse, this.dateStart, this.timeStart, this.dateEnd, this.timeEnd, this.update, this.creatorEmail, this.creatorName, this.organizerEmail, this.organizerName);

  var colorHash = 0xFF000000;

  String timePeriod() {
    String string = 'весь день';
    if (timeUse != 0 ) {
      if (dateStart == dateEnd) {
        string = "$timeStart - $timeEnd";
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

  String locationString() {
    String string = '';
    if (location != null) {
      string = location;
    }
    return string;
  }

  String descriptionString() {
    String string = '';
    RegExp exp = RegExp(r"\\n");
    if (description != null) {
      string = description;
    }
    string = string.replaceAll(exp, "\n");
    return string;
  }

  @override
  String toString() => "$eventId | $name | $location";
}