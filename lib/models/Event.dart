
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

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
  final calendarId;
  final url;
  String colorHash = '0xFF000000';
  var color = Color(0xFF770101);


  Event(
      this.eventId,
      this.name,
      this.description,
      this.location,
      this.timeUse,
      this.dateStart,
      this.timeStart,
      this.dateEnd,
      this.timeEnd,
      this.update,
      this.creatorEmail,
      this.creatorName,
      this.organizerEmail,
      this.organizerName,
      this.calendarId,
      this.url
      );



  String timePeriod() {
    String string = 'весь день';
    if (timeUse != 0 ) {
      if (dateStart == dateEnd) {
        string = "$timeStart - $timeEnd";
      } else {
        string = "from $dateStart $timeStart \nto $dateEnd $timeEnd";
      }
    } else {
      if (dateStart != dateEnd) {
        string = "from $dateStart to $dateEnd";
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
    if (description != null) {
      string = description;
    }
    RegExp exp = RegExp(r"\\n");
    string = string.replaceAll(exp, "\n");
    return string;
  }

  void setColorHash(String hash) {
    this.colorHash = hash;
  }



  dynamic getColorHash() {
    String colorCode = this.colorHash;
    return colorCode;
  }

  Digest getHashEvent() {
    var description = this.description;
    RegExp exp = RegExp(r" ");
    // description = description.replaceAll(exp, "");
    // exp = RegExp(r"\\n");
    // description = description.replaceAll(exp, "");
    // exp = RegExp(r"\n");
    // description = description.replaceAll(exp, "");
    // print(description);
    // var string = utf8.encode("${this.name}$description${this.dateStart}${this.dateEnd}${this.timeStart}${this.timeEnd}");
    // print("${this.name}${this.dateStart}${this.dateEnd}${this.timeStart}${this.timeEnd}");
    var string = utf8.encode("${this.name}${this.dateStart}${this.dateEnd}${this.timeStart}${this.timeEnd}");
    print(string);
    return md5.convert(string as List<int>);
  }

  @override
  String toString() => "$eventId || $name || $location";


}