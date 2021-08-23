import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/constants.dart';
import 'dart:io' as io;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class Classifier {
  Classifier();

  classifyImage(XFile? image) async {
    var _file = io.File(image!.path);
    img.Image? imageTemp = img.decodeImage(_file.readAsBytesSync());
    img.Image resizedImg = img.copyResize(imageTemp!, height: mnistSize, width: mnistSize);
    var imgBytes = resizedImg.getBytes();
    var imgAsList = imgBytes.buffer.asUint8List();

    return getPred(imgAsList);
  }

  classifyDrawing(List<Offset?> points) async {
    final picture = toPicture(points);
    final image = await picture.toImage(mnistSize, mnistSize);
    ByteData imBytes = await image.toByteData() as ByteData;
    var imgAsList = imBytes.buffer.asUint8List();

    return getPred(imgAsList);
}

  Future<int> getPred(Uint8List imgAsList) async {
    List resultBytes = List.filled(mnistSize * mnistSize, 0);

    int index = 0;
    for (int i = 0; i < imgAsList.lengthInBytes; i += 4) {
      final r = imgAsList[i];
      final g = imgAsList[i + 1];
      final b = imgAsList[i + 2];

      resultBytes[index] = ((r + g + b) / 3.0) / 255.0;
      index++;
    }

    var input = resultBytes.reshape([1, mnistSize, mnistSize, 1]);
    var output = List.filled(1 * 10, 0).reshape([1, 10]);

    InterpreterOptions interpreterOptions = InterpreterOptions();

    int startTime = new DateTime.now().millisecondsSinceEpoch;

    try {
      Interpreter interpreter = await Interpreter.fromAsset("model.tflite",
          options: interpreterOptions);
      interpreter.run(input, output);
    } catch (e) {
      print("Error occured while loading model: ${e.toString()}");
    }

    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}");

    double highestProb = 0;
    int digitPred = 0;

    for (int i = 0; i < output[0].length; i++) {
      if (output[0][i] > highestProb) {
        highestProb = output[0][i];
        digitPred = i;
      }
    }
    return digitPred;
  }
}

ui.Picture toPicture(List points) {
  final _whitePaint = Paint()
    ..strokeCap = StrokeCap.round
    ..color = Colors.white
    ..strokeWidth = 16.0;

  final _bgPaint = Paint()..color = Colors.black;
  final _canvasCullRect = Rect.fromPoints(Offset(0, 0),
      Offset(mnistSize.toDouble(), mnistSize.toDouble()));
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, _canvasCullRect)
    ..scale(mnistSize / canvasSize);

  canvas.drawRect(Rect.fromLTWH(0, 0, 28, 28), _bgPaint);

  for (int i = 0; i < points.length - 1; i++) {
    if (points[i] != null && points[i + 1] != null) {
      canvas.drawLine(points[i], points[i + 1], _whitePaint);
    }
  }
  return recorder.endRecording();
}