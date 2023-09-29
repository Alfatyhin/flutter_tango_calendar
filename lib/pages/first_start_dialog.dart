
import 'package:flutter/material.dart';

class FirstStartMain {

  FirstStartMain();

  Future<void> screenFirstStart0(BuildContext context) async {

    print('screenFirstStart0');

    return  showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Text("First start help",
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue
                  ),
                ),
              ),
            ],
          ),
        );
      },
      anchorPoint: Offset(1000, 1000),
    );
  }
}