import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionBox extends StatelessWidget {
  final Face face;
  final String emotion;
  final Size imageSize;
  final Size screenSize;
  final InputImageRotation rotation;

  const FaceDetectionBox({
    super.key,
    required this.face,
    required this.emotion,
    required this.imageSize,
    required this.screenSize,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    final boundingBox = face.boundingBox;

    // Calcular la transformación de coordenadas
    double scaleX, scaleY;
    double left, top, width, height;

    switch (rotation) {
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        scaleX = screenSize.width / imageSize.width;
        scaleY = screenSize.height / imageSize.height;
        left = boundingBox.left * scaleX;
        top = boundingBox.top * scaleY;
        width = boundingBox.width * scaleX;
        height = boundingBox.height * scaleY;
        break;

      case InputImageRotation.rotation90deg:
        scaleX = screenSize.width / imageSize.height;
        scaleY = screenSize.height / imageSize.width;
        left = boundingBox.top * scaleX;
        top = (imageSize.width - boundingBox.right) * scaleY;
        width = boundingBox.height * scaleX;
        height = boundingBox.width * scaleY;
        break;

      case InputImageRotation.rotation270deg:
        scaleX = screenSize.width / imageSize.height;
        scaleY = screenSize.height / imageSize.width;
        left = (imageSize.height - boundingBox.bottom) * scaleX;
        top = boundingBox.left * scaleY;
        width = boundingBox.height * scaleX;
        height = boundingBox.width * scaleY;
        break;
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The face bounding box
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.deepPurple, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          // Label positioned above the box without using negative margins
          Positioned(
            top: -24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  emotion,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
