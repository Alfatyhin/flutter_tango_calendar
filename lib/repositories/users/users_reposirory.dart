import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/UserData.dart';



class usersRepository {

  FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> addNewUser(UserData userData) async {
    final user = userData.toFirestore();
    await db.collection('usersData').doc(userData.uid).set(user);
  }

  Future<UserData> getUserDataByUid(userUid) async {
    var userData;
    final ref = db.collection('usersData').doc(userUid).withConverter(
      fromFirestore: UserData.fromFirestore,
      toFirestore: (UserData userData, _) => userData.toFirestore(),
    );
    final docSnap = await ref.get();
    userData = docSnap.data(); // Convert
    if (userData != null) {
      return userData;
    } else {
      print("No such document.");
    }

    return userData;
  }

  Future<List> getUsersDataByUids(List usersUds) async {

    return db.collection("usersData").where('uid', whereIn: usersUds).withConverter(
      fromFirestore: UserData.fromFirestore,
      toFirestore: (UserData userData, _) => userData.toFirestore(),
    ).get().then(
          (querySnapshot) {
        List users = [];
        print("Successfully completed");
        for (var docSnapshot in querySnapshot.docs) {
          users.add(docSnapshot.data());
        }
        return users;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<List> getUsers() async {

    return db.collection("usersData").orderBy("createdDt", descending: true).limit(20).withConverter(
      fromFirestore: UserData.fromFirestore,
      toFirestore: (UserData userData, _) => userData.toFirestore(),
    ).get().then(
          (querySnapshot) {
            List users = [];
            print("Successfully completed");
            for (var docSnapshot in querySnapshot.docs) {
              users.add(docSnapshot.data());
            }
            return users;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<String> changeUserData(userUid, fieldName, fieldValue) async {
    return db.collection("usersData")
        .doc(userUid)
        .update({'${fieldName}': fieldValue})
        .then((value) {
      print("User Updated");
      return 'User Updated';
    })
        .catchError((error) {
      print("Failed to update user: $error");
      return 'Failed to update user';
    });
  }

  Future<String> deleteUserData(userUid) async {
    return db.collection("usersData")
        .doc(userUid)
        .delete()
        .then((value) {
      print("User Delete");
      return 'User Delete';
    })
        .catchError((error) {
      print("Failed to delete user: $error");
      return 'Failed to delete user';
    });
  }

  Future statementsAdd(Map<String, dynamic> applicateData) async {
    var key = '${applicateData['userUid']}-${applicateData['type']}';

    db.collection('statements').doc(key).set(applicateData);
  }

  Future addFbEventImportSettings(Map<String, dynamic> applicateData) async {
    var key = '${applicateData['calId']}-${applicateData['eventId']}';

    db.collection('fbEventImportSettings').doc(key).set(applicateData);
  }

  Future<Map> getFbEventImportSettingsByCalId(calId) async {
    Map importSettings = {};
    return db.collection('fbEventImportSettings')
        .where('calId', isEqualTo: calId)
        .get()
        .then(
          (querySnapshot) {
        for (var docSnapshot in querySnapshot.docs) {
          var eventId = docSnapshot['eventId'];

          importSettings[eventId] = docSnapshot.data();
        }

        return importSettings;
      },
      onError: (e) => print("Error updating document $e"),
    );
  }

  Future<Map> getFbEventImportSettingsByEventId(eventId) async {
    Map importSettings = {};
    return db.collection('fbEventImportSettings')
        .where('eventId', isEqualTo: eventId)
        .get()
        .then(
          (querySnapshot) {
        for (var docSnapshot in querySnapshot.docs) {
          var eventId = docSnapshot['eventId'];

          importSettings[eventId] = docSnapshot.data();
        }

        return importSettings;
      },
      onError: (e) => print("Error updating document $e"),
    );
  }



  Future<List> getNewStatements() async {

    return db.collection("statements").where("status", isEqualTo: 'new').get().then(
          (querySnapshot) {
            var dataList = [];
            for (var docSnapshot in querySnapshot.docs) {
              var data = docSnapshot.data();
              data['id'] = docSnapshot.id;
              dataList.add(data);
            }
            return dataList;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }



  Future<int> getStatementsCount() async {

    return db.collection("statements")
        .where("status", isEqualTo: 'new')
        .count()
        .get().then(
          (res) {
        return res.count;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }



  Future<String> changeStatmentData(id, data) async {
    return db.collection("statements")
        .doc(id)
        .update(data)
        .then((value) {
      print("Statment Updated");
      return 'Statment Updated';
    })
        .catchError((error) {
      print("Failed to update Statment: $error");
      return 'Failed to update Statment';
    });
  }

  Future<String> setCalendarsPermissions(data) async {
    var id = '${data['calId']}-${data['userUid']}';
    return db.collection("calendarPermissions")
        .doc(id)
        .set(data)
        .then((value) {
      print("Calendars Permissions Updated");
      return 'Calendars Permissions Updated';
    })
        .catchError((error) {
      print("Failed to update Calendars Permissions: $error");
      return 'Failed to update Calendars Permissions';
    });
  }

  Future<String> setUserEventPermissions(data) async {
    var id = '${data['eventId']}-${data['userUid']}';
    return db.collection("eventsPermissions")
        .doc(id)
        .set(data)
        .then((value) {
      print("Events Permissions Updated");
      return 'Events Permissions Updated';
    })
        .catchError((error) {
      print("Failed to update Events Permissions: $error");
      return 'Failed to update Events Permissions';
    });
  }


  Future<Map> getEventsPermissions(eventGUid) {
    return db.collection("eventsPermissions").where('eventId', isEqualTo: eventGUid)
        .get()
        .then(
          (querySnapshot) {
        Map data = {};
        print("Successfully completed");
        var x = 0;
        for (var docSnapshot in querySnapshot.docs) {
          var doc = docSnapshot.data();
          data[x] = {
            'userUid': doc['userUid'],
            'add': doc['add'],
            'redact': doc['redact'],
            'delete': doc['delete']
          };
          x++;
        };
        return data;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<Map> getUserEventsPermissions(userUid) {
    return db.collection("eventsPermissions").where('userUid', isEqualTo: userUid)
        .get()
        .then(
          (querySnapshot) {
        Map data = {};
        print("Successfully completed");
        for (var docSnapshot in querySnapshot.docs) {
          var doc = docSnapshot.data();
          data[doc['eventId']] = {
            'add': doc['add'],
            'redact': doc['redact'],
            'delete': doc['delete']
          };
        };
        return data;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future deleteUserEventsPermissions(eventId) {

    return db.collection("eventsPermissions").where('eventId', isEqualTo: eventId)
        .get()
        .then(
          (querySnapshot) {
        for (var docSnapshot in querySnapshot.docs) {
          var docId = docSnapshot.id;

          db.collection("eventsPermissions")
              .doc(docId)
              .delete()
              .then((value) {
            print("Event permission Delete");
          })
              .catchError((error) {
            print("Failed to delete Event permission: $error");
          });
        };

      },
      onError: (e) => print("Error completing: $e"),
    );

  }

  Future<Map<String, dynamic>> getUserTokenByUid(userUid) async {
    return db.collection('usersTokens').doc(userUid).get().then(
          (DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<String> setUserToken(data) async {
    var id = '${data['userUid']}';
    return db.collection("usersTokens")
        .doc(id)
        .set(data)
        .then((value) {
      print("usersTokens Updated");
      return 'usersTokens Updated';
    })
        .catchError((error) {
      print("Failed to update usersTokens: $error");
      return 'Failed to update usersTokens';
    });
  }

}