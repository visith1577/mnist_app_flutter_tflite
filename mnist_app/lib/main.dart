import 'package:flutter/material.dart';
import './pages/upload_page.dart';
import './pages/drawing_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: Home()
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentIndex = 0;
  List tabs = [
    UploadImage(),
    Drawing(),
  ];
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: tabs[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex, 
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.image_search), label: "Image"),
            BottomNavigationBarItem(icon: Icon(Icons.album), label: "Draw")
          ],
        onTap: (index) => setState(() => currentIndex = index),
      ),
    );
  }
}