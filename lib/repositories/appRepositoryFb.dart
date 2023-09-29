
import '../../AppTools.dart';

class AppRepository {

  Future<List> getAppData() async {

    return db.collection('appValues')
        .get().then(
          (querySnapshot) {
        List data = [];
        print("Successfully completed");
        for (var docSnapshot in querySnapshot.docs) {
          data.add(docSnapshot.data());
        }
        return data;
      },
      onError: (e) => print("Error completing: $e"),
    );
  }


}