
class Calendar {

  final String id;
  final String name;
  final String description;
  final String typeEvents;
  final String country;
  final String city;
  final String source;
  bool _enable = false;

  Calendar(this.id, this.name, this.description, this.typeEvents, this.country, this.city, this.source);


  bool get enable => _enable;

  set enable(bool value) {
    _enable = value;
  }

}