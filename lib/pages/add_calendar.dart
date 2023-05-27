import 'package:flutter/material.dart';
import '../AppTools.dart';


class GeoEvents extends StatefulWidget {
  const GeoEvents({Key? key}) : super(key: key);

  @override
  _GeoEventsState createState() => _GeoEventsState();
}


class _GeoEventsState extends State<GeoEvents> {
  
  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Geo Events'),
        ),
        actions: [

        ],
      ),
      body: ListView(
        children: [
          Text('geo')
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete, color: Colors.white,),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.refresh),
            label: 'update',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightBlueAccent[800],
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) async {
    switch (index) {
      case 0:
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
      case 1:

        break;
      case 2:

        break;
    }

  }

}

