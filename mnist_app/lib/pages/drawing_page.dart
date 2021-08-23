import 'package:flutter/material.dart';
import '../model/classifier.dart';
import '../utils/constants.dart';
import 'dart:ui' as ui;

class Drawing extends StatefulWidget {
  @override
  _DrawingState createState() => _DrawingState();
}

class _DrawingState extends State<Drawing> {
  int digit = -1;
  List<Offset?> points = [];
  final pointMode = ui.PointMode.points;
  Classifier classifier = Classifier();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black54,
        child: Icon(Icons.close),
        onPressed: () => setState(() {
          points.clear();
          digit = -1;
        }),
      ),
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent,
        title: Text("Drawing pad"),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Draw digit below",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Container(
              height: canvasSize + borderSize*2,
              width: canvasSize + borderSize*2,
              // color: Colors.white60,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: borderSize,
                ),
              ),
              child: GestureDetector(
                onPanUpdate: (DragUpdateDetails details) {
                  Offset _localPosition = details.localPosition;
                  if (_localPosition.dx >= 0 &&
                      _localPosition.dx <= 300 &&
                      _localPosition.dy >= 0 &&
                      _localPosition.dy <= 300) {
                    setState(() {
                      points.add(_localPosition);
                    });
                  }
                },
                onPanEnd: (DragEndDetails details) async {
                  points.add(null);
                  digit = await classifier.classifyDrawing(points);
                  setState(() {});
                },
                child: CustomPaint(
                  painter: Painter(points: points),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                "Current Prediction",
                style: TextStyle(
                  fontSize: 23,
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Text(digit == -1 ? "" : "$digit",
                style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class Painter extends CustomPainter {
  List points = [];

  Painter({required this.points});

  final Paint _paintDetails = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth =
        4.0 // strokeWidth 4 looks good, but strokeWidth approx. 16 looks closer to training data
    ..color = Colors.black;

  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], _paintDetails);
      }
    }
  }

  bool shouldRepaint(Painter oldDelegate) => true;
}
