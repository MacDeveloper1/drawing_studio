import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'enumdart';
import 'shape.dart';

/// The controller for shape painting.
class ShapePaintingController extends ChangeNotifier {
  ShapePaintingController({
    ZonesPaintingState state = const ZonesPaintingState(),
    this.onShapesUpdate,
  }) : _state = state;

  /// Calls back when painted shapes changed.
  final ValueChanged<List<PolygonShape>>? onShapesUpdate;

  ZonesPaintingState _state;

  PaintingTool get paintingTool => _state.paintingTool;
  List<PolygonShape> get shapes => _state.shapes;
  List<PolygonShape> get selectedShapes => _state.selectedShapes;
  List<Offset> get openedVertices => _state.openedVertices;
  Offset get currentPosition => _state.currentPosition;
  Offset get selectionRectOffset => _state.selectionRectOffset;

  bool get isSelectionRectEnabled =>
      selectionRectOffset.isFinite && currentPosition.isFinite;

  /// Generates a next shape identifier.
  int getNextShapeId() =>
      (maxBy(shapes.map((polygon) => polygon.id), (id) => id) ?? 0) + 1;

  void updatePaintingTool(PaintingTool paintingTool) {
    _emit(_state.copyWith(
      paintingTool: paintingTool,
      selectionRectOffset: Offset.infinite,
      currentPosition: Offset.infinite,
    ));
  }

  void updateCurrentPosition(Offset position) {
    switch (_state.paintingTool) {
      case PaintingTool.scrolling:
        break;
      case PaintingTool.drawing:
        _emit(_state.copyWith(currentPosition: position));
      case PaintingTool.selection:
        break;
    }
  }

  void startSelection(Offset position) {
    if (!paintingTool.isSelection) return;
    _emit(_state.copyWith(selectionRectOffset: position));
  }

  void updateSelection(Offset position) {
    if (!paintingTool.isSelection) return;
    _emit(_state.copyWith(currentPosition: position));

    final selectedShapes = [..._state.selectedShapes];
    final selectionPath = Path()
      ..addRect(_state.selectionRect)
      ..close();

    // Check whether the selection rectangle overlap any shape.
    for (final shape in _state.shapes) {
      final shapePath = shape.getOuterPath(Rect.zero);
      final intersection =
          Path.combine(PathOperation.intersect, shapePath, selectionPath);
      if (intersection.getBounds().isEmpty) {
        selectedShapes.remove(shape);
      } else {
        if (selectedShapes.contains(shape)) continue;
        selectedShapes.add(shape);
      }
    }

    _emit(_state.copyWith(selectedShapes: selectedShapes));
  }

  void cancelSelection() {
    if (!paintingTool.isSelection) return;
    _emit(_state.copyWith(
      currentPosition: Offset.infinite,
      selectionRectOffset: Offset.infinite,
    ));
  }

  void addVertex(Offset position) {
    if (!paintingTool.isDrawing) return;
    if (_state.openedVertices.contains(position)) return;
    _emit(_state.copyWith(
      openedVertices: [..._state.openedVertices, position],
      selectedShapes: <PolygonShape>[],
      currentPosition: position,
    ));
  }

  void closeShape(Offset position) {
    if (!paintingTool.isDrawing) return;
    final shapes = [..._state.shapes];
    final selectedShapes = [..._state.selectedShapes];
    final vertices = [..._state.openedVertices, position];
    if (vertices.length >= PolygonShape.validVertexCount) {
      final index = getNextShapeId();
      final shape = PolygonShape(
        id: index,
        name: 'Zone $index',
        vertices: vertices,
      );
      shapes.add(shape);
      selectedShapes.add(shape);
    }
    _emit(_state.copyWith(
      shapes: shapes,
      selectedShapes: selectedShapes,
      openedVertices: [],
    ));
  }

  void selectShape(PolygonShape shape) {
    final selectedShapes = HardwareKeyboard.instance.isShiftPressed
        ? [..._state.selectedShapes]
        : <PolygonShape>[];
    if (selectedShapes.contains(shape)) return;
    _emit(_state.copyWith(selectedShapes: selectedShapes..add(shape)));
  }

  void clearSelectedShapes() {
    _emit(_state.copyWith(selectedShapes: []));
  }

  void moveSelectedShapes(Offset delta) {
    if (_state.selectedShapes.isEmpty) return;
    final movableShapes =
        _state.selectedShapes.map((shape) => shape.copyWith()).toList();
    final shapes = [...this.shapes];
    for (final movableShape in movableShapes) {
      final movableShapeIndex =
          _state.shapes.indexWhere((shape) => shape == movableShape);
      for (var i = 0; i < movableShape.vertices.length; i++) {
        movableShape.vertices[i] = movableShape.vertices[i] + delta;
      }
      shapes[movableShapeIndex] = movableShape;
    }
    _emit(_state.copyWith(
      shapes: shapes,
      selectedShapes: [...movableShapes],
    ));
  }

  void moveSelectedVertex(int index, Offset delta) {
    if (_state.selectedShapes.isEmpty) return;
    final movableShape = _state.selectedShapes.first.copyWith();
    final movableShapeIndex =
        _state.shapes.indexWhere((shape) => shape == movableShape);
    final selectedVertex = movableShape.vertices[index];
    movableShape.vertices[index] = selectedVertex + delta;
    _emit(_state.copyWith(
      shapes: [...shapes]..[movableShapeIndex] = movableShape,
      selectedShapes: [movableShape],
    ));
  }

  void removeOpenedShape() {
    if (openedVertices.isEmpty) return;
    _emit(_state.copyWith(openedVertices: []));
  }

  void removeShape(PolygonShape area) {
    if (shapes.isEmpty) return;
    _emit(_state.copyWith(
      shapes: shapes.toList()..remove(area),
      selectedShapes: selectedShapes.toList()..remove(area),
    ));
  }

  void removeAllShapes() {
    if (shapes.isEmpty) return;
    _emit(_state.copyWith(shapes: [], selectedShapes: []));
  }

  void removeSelectedShapes() {
    while (selectedShapes.isNotEmpty) {
      removeShape(selectedShapes.first);
    }
  }

  bool isShapeSelected(PolygonShape shape) {
    return selectedShapes.contains(shape);
  }

  void _emit(ZonesPaintingState state) {
    if (_state == state) return;

    if (_state.shapes != state.shapes) {
      onShapesUpdate?.call(state.shapes);
    }

    _state = state;
    notifyListeners();
    //print(state);
  }
}

/// The immutable current state of [ShapePaintingController].
@immutable
class ZonesPaintingState {
  const ZonesPaintingState({
    this.paintingTool = PaintingTool.scrolling,
    this.shapes = const <PolygonShape>[],
    this.selectedShapes = const <PolygonShape>[],
    this.openedVertices = const <Offset>[],
    this.currentPosition = Offset.infinite,
    this.selectionRectOffset = Offset.infinite,
  });

  final PaintingTool paintingTool;
  final List<PolygonShape> shapes;
  final List<PolygonShape> selectedShapes;
  final List<Offset> openedVertices;
  final Offset currentPosition;
  final Offset selectionRectOffset;

  Rect get selectionRect => Rect.fromPoints(
        selectionRectOffset.isFinite ? selectionRectOffset : Offset.zero,
        currentPosition.isFinite ? currentPosition : Offset.zero,
      );

  ZonesPaintingState copyWith({
    PaintingTool? paintingTool,
    List<PolygonShape>? shapes,
    List<PolygonShape>? selectedShapes,
    List<Offset>? openedVertices,
    Offset? currentPosition,
    Offset? selectionRectOffset,
  }) =>
      ZonesPaintingState(
        paintingTool: paintingTool ?? this.paintingTool,
        shapes: shapes ?? [...this.shapes],
        selectedShapes: selectedShapes ?? [...this.selectedShapes],
        openedVertices: openedVertices ?? [...this.openedVertices],
        currentPosition: currentPosition ?? this.currentPosition,
        selectionRectOffset: selectionRectOffset ?? this.selectionRectOffset,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZonesPaintingState &&
          paintingTool == other.paintingTool &&
          listEquals<PolygonShape>(shapes, other.shapes) &&
          listEquals<PolygonShape>(selectedShapes, other.selectedShapes) &&
          listEquals<Offset>(openedVertices, other.openedVertices) &&
          currentPosition == other.currentPosition &&
          selectionRectOffset == other.selectionRectOffset;

  @override
  int get hashCode => Object.hashAll([
        paintingTool,
        shapes,
        selectedShapes,
        openedVertices,
        currentPosition,
        selectionRectOffset,
      ]);

  @override
  String toString() {
    final properties = [
      'mode: ${paintingTool.name}',
      'position: $currentPosition',
      'vertices: $openedVertices',
      'shapes: $shapes',
      'selection: $selectedShapes',
    ].join(', ');
    return '$runtimeType {$properties}';
  }
}
