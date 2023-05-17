import 'package:cloud_firestore/cloud_firestore.dart';

class Calendar {

  final id;
  final name;
  final description;
  final typeEvents;
  final country;
  final city;
  final source;
  final gcalendarId;
  final creator;
  bool _enable = false;

  Calendar({
    this.id,
    this.name,
    this.description,
    this.typeEvents,
    this.country,
    this.city,
    this.source,
    this.gcalendarId,
    this.creator
  });


  Map<String, Object> toJson(){
    return{
      "id": id,
      "name": name,
      "description": description,
      "typeEvents": typeEvents,
      "country": country,
      "city": city,
      "source": source,
      "gcalendarId": gcalendarId,
      "creator": creator
    };
  }


  bool get enable => _enable;

  set enable(bool value) {
    _enable = value;
  }


  factory Calendar.fromLocalData(data) {
    return Calendar(
      id: data?['id'],
      name: data?['name'],
      description: data?['description'],
      typeEvents: data?['typeEvents'],
      country: data?['country'],
      city: data?['city'],
      source: data?['source'],
      gcalendarId: data?['gcalendarId'],
      creator: data?['creator'],
    );
  }

  factory Calendar.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return Calendar(
      id: data?['id'],
      name: data?['name'],
      description: data?['description'],
      typeEvents: data?['typeEvents'],
      country: data?['country'],
      city: data?['city'],
      source: data?['source'],
      gcalendarId: data?['gcalendarId'],
      creator: data?['creator'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) "id": id,
      if (name != null) "name": name,
      if (description != null) "description": description,
      if (typeEvents != null) "typeEvents": typeEvents,
      if (country != null) "country": country,
      if (city != null) "city": city,
      if (source != null) "source": source,
      if (gcalendarId != null) "gcalendarId": gcalendarId,
      if (creator != null) "creator": creator,
    };
  }


}