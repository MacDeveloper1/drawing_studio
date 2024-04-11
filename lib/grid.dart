import 'package:flutter/material.dart';

/// Draws the underlying drawing grid.
class DrawingGridPainter extends CustomPainter {
  const DrawingGridPainter({this.majorCellSize = 50, this.minorCellSize = 10});

  final double majorCellSize;
  final double minorCellSize;

  @override
  void paint(Canvas canvas, Size size) {
    _drawMinorCells(canvas, size);
    _drawMajorCells(canvas, size);
  }

  void _drawMinorCells(Canvas canvas, Size size) {
    final minorHCount = size.height / minorCellSize;
    final minorVCount = size.width / minorCellSize;

    final minorLinePaint = Paint().stroke(color: Colors.grey.shade200);

    double minorCoordinate(int index) => (index * minorCellSize).toDouble();

    for (var i = 1; i < minorHCount; i++) {
      canvas.drawLine(Offset(0, minorCoordinate(i)),
          Offset(size.width, minorCoordinate(i)), minorLinePaint);
    }

    for (var i = 1; i < minorVCount; i++) {
      canvas.drawLine(Offset(minorCoordinate(i), 0),
          Offset(minorCoordinate(i), size.height), minorLinePaint);
    }
  }

  void _drawMajorCells(Canvas canvas, Size size) {
    final majorHCount = size.height / majorCellSize;
    final majorVCount = size.width / majorCellSize;

    final majorLinePaint = Paint().stroke(color: Colors.grey.shade400);

    double majorCoordinate(int index) => (index * majorCellSize).toDouble();

    for (var i = 1; i < majorHCount; i++) {
      canvas.drawLine(Offset(0, majorCoordinate(i)),
          Offset(size.width, majorCoordinate(i)), majorLinePaint);
    }

    for (var i = 1; i < majorVCount; i++) {
      canvas.drawLine(Offset(majorCoordinate(i), 0),
          Offset(majorCoordinate(i), size.height), majorLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingGridPainter oldDelegate) =>
      majorCellSize != oldDelegate.majorCellSize ||
      minorCellSize != oldDelegate.minorCellSize;
}

extension on Paint {
  Paint stroke({
    Color color = Colors.black,
    double strokeWidth = 1.0,
    StrokeCap strokeCap = StrokeCap.butt,
    StrokeJoin strokeJoin = StrokeJoin.round,
  }) =>
      this
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = strokeCap
        ..strokeJoin = strokeJoin;
}
