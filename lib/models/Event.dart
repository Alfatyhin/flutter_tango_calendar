
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

  Event(this.eventId, this.name, this.description, this.location, this.timeUse, this.dateStart, this.timeStart, this.dateEnd, this.timeEnd, this.update, this.creatorEmail, this.creatorName, this.organizerEmail, this.organizerName);

  String timePeriod() {
    String string = 'весь день';
    if (timeUse != 0 ) {
      if (dateStart == dateEnd) {
        string = "$timeStart - $timeEnd";
      } else {
        string = "с $dateStart $timeStart по $dateEnd $timeEnd";
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

  @override
  String toString() => "$eventId | $name | $location";
}