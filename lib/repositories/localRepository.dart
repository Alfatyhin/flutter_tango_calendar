import 'package:shared_preferences/shared_preferences.dart';

class localRepository {

  Future clearLocalData(key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future setLocalDataString(key, data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, data);
  }

  Future<String?> getLocalDataString(key) async {
    final prefs = await SharedPreferences.getInstance();
    String? string;
    if (prefs.containsKey(key)) {
      string = await prefs.getString(key);
    } else {
      string = '';
    }
    return string;
  }

}