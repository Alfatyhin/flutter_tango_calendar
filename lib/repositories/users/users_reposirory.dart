import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/UserData.dart';



class usersRepository {

  FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> addNewUser(UserData userData) async {
    final user = userData.toJson();
    await db.collection('usersData').doc(userData.uid).set(user);
  }

  Future<UserData> getUserDataByUid(userUid) async {
    var userData;
    print('------------');
    print(userUid);

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

  Future statementsAdd(Map<String, dynamic> applicateData) async {
    var key = '${applicateData['userUid']}-${applicateData['type']}';

    db.collection('statements').doc(key).set(applicateData);
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

}