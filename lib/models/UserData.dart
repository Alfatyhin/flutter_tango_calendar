
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/localRepository.dart';

class UserData {
  final uid;
  final name;
  final email;
  final role;
  final phone;
  final createdDt;
  final updatedDt;

  UserData({this.uid, this.name, this.email, this.role, this.phone, this.createdDt, this.updatedDt});


  factory UserData.fromLocalData(data) {
    // Future<String?> str = localRepository().getLocalDataString('userData');
    // var data = json.decode(str as String);
    return UserData(
      uid: data?['uid'],
      name: data?['name'],
      email: data?['email'],
      role: data?['role'],
      phone: data?['phone'],
      createdDt: data?['createdDt'],
      updatedDt: data?['updatedDt'],
    );
  }

  Map<String, Object> toJson(){
    return{
      "uid": uid,
      "name": name,
      "email": email,
      "phone": phone,
      "role": role,
      "createdDt": createdDt,
      "updatedDt": updatedDt
    };
  }

  factory UserData.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return UserData(
      uid: data?['uid'],
      name: data?['name'],
      email: data?['email'],
      role: data?['role'],
      phone: data?['phone'],
      createdDt: data?['createdDt'],
      updatedDt: data?['updatedDt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (uid != null) "uid": uid,
      if (name != null) "name": name,
      if (email != null) "email": email,
      if (role != null) "role": role,
      if (phone != null) "phone": phone,
      if (createdDt != null) "createdDt": createdDt,
      if (updatedDt != null) "updatedDt": updatedDt,
    };
  }

}