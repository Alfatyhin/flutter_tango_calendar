import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class localRepository {

  Future clearLocalData(key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future setLocalDataBool(key, data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, data);
  }

  Future getLocalDataBool(key) async {
    final prefs = await SharedPreferences.getInstance();
    var res = await prefs.getBool(key);
    print('test $key - $res');
    if (res == null)
      res = false;

    return res;
  }

  Future setLocalDataString(key, data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, data);
  }

  Future setLocalDataJson(key, data) async {
    final prefs = await SharedPreferences.getInstance();
    String dataString = json.encode(data);
    await prefs.setString(key, dataString);
  }

  Future setLocalDataDouble(key, data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, data);
  }

  Future<String?> getLocalDataString(key) async {
    final prefs = await SharedPreferences.getInstance();
    String? string = '';
    if (prefs.containsKey(key)) {
      string = await prefs.getString(key);
    }
    return string;
  }

  Future<double?> getLocalDataDouble(key) async {
    final prefs = await SharedPreferences.getInstance();
    double? value = 0;
    if (prefs.containsKey(key)) {
      value = await prefs.getDouble(key);
    }
    return value;
  }

}