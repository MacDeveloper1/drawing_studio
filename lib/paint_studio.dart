import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'enumdart';
import 'shape.dart';

class ShapePaintingStudio extends StatefulWidget {
  const ShapePaintingStudio({
    super.key,
    required this.controller,
  });

  final ShapePaintingController controller;

  @override
  State<ShapePaintingStudio> createState() => _ShapePaintingStudioState();
}

class _ShapePaintingStudioState extends State<ShapePaintingStudio> {
  Timer? _clickTimer;

  int _clickCounter = 0;
  bool _wasSecondaryButtonPressed = false;

  ShapePaintingController get _controller => widget.controller;
  PaintingTool get _paintingTool => _controller.paintingTool;

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyPress);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyPress);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Listener(
      onPointerDown: _paintingTool.isScrolling ? null : _handlePointerDown,
      onPointerHover: _paintingTool.isScrolling ? null : _handlePointerHover,
      child: MouseRegion(
        cursor: _paintingTool.isDrawing
            ? SystemMouseCursors.precise
            : MouseCursor.defer,
        child: Stack(
          children: [
            if (_paintingTool.isSelection)
              GestureDetector(
                onPanDown: (details) =>
                    _controller.startSelection(details.localPosition),
                onPanUpdate: (details) =>
                    _controller.updateSelection(details.localPosition),
                onPanEnd: (details) => _controller.cancelSelection(),
                onTap: () => _controller.clearSelectedShapes(),
              ),
            // Draw closed shapes
            ..._controller.shapes.map((shape) {
              final isShapeSelected = _controller.isShapeSelected(shape);
              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: shape.color ?? Colors.grey.withOpacity(0.3),
                  shadows: isShapeSelected
                      ? [
                          const BoxShadow(
                            color: Colors.black,
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: Offset(1, 1),
                            blurStyle: BlurStyle.outer,
                          ),
                        ]
                      : null,
                  shape: PolygonShape(
                    id: shape.id,
                    name: shape.name,
                    vertices: shape.vertices,
                    side: BorderSide(
                      color: isShapeSelected
                          ? theme.colorScheme.primary
                          : Colors.black,
                      width: 3,
                    ),
                  ),
                ),
                child: GestureDetector(
                  onTap: () => _controller.selectShape(shape),
                  onPanUpdate: (details) =>
                      _controller.moveSelectedShapes(details.delta),
                  child: MouseRegion(
                    cursor: isShapeSelected
                        ? SystemMouseCursors.grab
                        : MouseCursor.defer,
                  ),
                ),
              );
            }),
            // Draw selected vertices
            ..._controller.selectedShapes
                .expand((shape) => shape.vertices)
                .mapIndexed((index, vertex) {
              return Positioned.fromRect(
                rect: Rect.fromCircle(center: vertex, radius: 4),
                child: Container(
                  decoration: ShapeDecoration(
                    shape: const CircleBorder(),
                    color: theme.colorScheme.primary,
                    shadows: const [
                      BoxShadow(
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: Offset(1, 1),
                        blurStyle: BlurStyle.normal,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onPanUpdate: (details) =>
                        _controller.moveSelectedVertex(index, details.delta),
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.move,
                    ),
                  ),
                ),
              );
            }),
            // Draw current shape as selected
            if (_controller.openedVertices.isNotEmpty)
              () {
                final index = _controller.getNextShapeId();
                final vertices = (_controller.openedVertices.toSet()
                      ..add(_controller.currentPosition))
                    .toList();
                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    shape: PolygonShape(
                      id: index,
                      name: 'Zone $index',
                      vertices: vertices,
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }(),
            // Draw opened vertices as selected
            ..._controller.openedVertices.map((vertex) {
              return Positioned.fromRect(
                rect: Rect.fromCircle(center: vertex, radius: 4),
                child: Container(
                  decoration: ShapeDecoration(
                    shape: const CircleBorder(),
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            }),
            // Draw selection region
            if (_controller.isSelectionRectEnabled)
              Positioned.fromRect(
                rect: Rect.fromPoints(_controller.selectionRectOffset,
                    _controller.currentPosition),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons == kPrimaryMouseButton) {
      if (_wasSecondaryButtonPressed) {
        _wasSecondaryButtonPressed = false;
        return;
      }

      _clickCounter += 1;

      if (_clickTimer == null) {
        _clickTimer = Timer(const Duration(milliseconds: 180), () {
          if (_clickCounter == 1) {
            _resetPointerTimer();
            _handlePointerTap(event);
          }
        });
      } else {
        if (_clickTimer!.tick < 400) {
          if (_clickCounter == 2) {
            _resetPointerTimer();
            _handlePointerDoubleTap(event);
          }
        }
      }
    } else if (event.buttons == kSecondaryButton) {
      _wasSecondaryButtonPressed = true;
    }
  }

  void _resetPointerTimer() {
    _clickCounter = 0;
    _clickTimer = null;
  }

  void _handlePointerTap(PointerDownEvent event) {
    switch (_paintingTool) {
      case PaintingTool.scrolling:
        break;
      case PaintingTool.selection:
        break;
      case PaintingTool.drawing:
        _controller.addVertex(event.localPosition);
    }
  }

  void _handlePointerDoubleTap(PointerDownEvent event) {
    switch (_paintingTool) {
      case PaintingTool.scrolling:
        break;
      case PaintingTool.selection:
        break;
      case PaintingTool.drawing:
        _controller.closeShape(event.localPosition);
    }
  }

  void _handlePointerHover(PointerHoverEvent event) {
    _controller.updateCurrentPosition(event.localPosition);
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.escape:
          _controller.removeOpenedShape();
        case LogicalKeyboardKey.delete:
          _controller.removeSelectedShapes();
      }
    }
    return false;
  }
}
