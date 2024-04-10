import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The painting shape which contains vertices and edges.
class PolygonShape extends OutlinedBorder {
  const PolygonShape({
    required this.id,
    required this.vertices,
    this.name = '',
    this.color,
    super.side,
  });

  PolygonShape.fromJson(Map<String, dynamic> map)
      : id = map['id'],
        vertices = List.from(map['vertices'])
            .map((vertex) => Offset(vertex['dx'], vertex['dy']))
            .toList(),
        name = map['name'],
        color = map['color'],
        super(side: BorderSide.none);

  /// The number of vertices which makes the shape valid.
  static const int validVertexCount = 3;

  /// The unique identifier of this shape.
  final int id;

  /// The list of vertices from which the border consists.
  final List<Offset> vertices;

  /// The name of this shape.
  final String name;

  /// The background color of this shape.
  final Color? color;

  /// Indicates whether this shape is valid.
  bool get isValid => vertices.length >= validVertexCount;

  /// Inficates whether this shape has a color.
  bool get hasColor => color != null;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'vertices': vertices
            .map((vertex) => {
                  'dx': vertex.dx.with1decimal(),
                  'dy': vertex.dy.with1decimal()
                })
            .toList(),
        if (name.isNotEmpty) 'name': name,
        if (hasColor) 'color': color,
      };

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPolygon(vertices, true);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return (Path()
          ..addPolygon(vertices, true)
          ..addPath(getInnerPath(rect), Offset.zero))
        .shift(rect.topLeft);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final path = getOuterPath(rect, textDirection: textDirection);
    canvas.drawPath(path, side.toPaint());
  }

  @override
  ShapeBorder scale(double t) {
    return PolygonShape(
      id: id,
      vertices: vertices.map((vertex) => vertex.scale(t, t)).toList(),
      name: name,
      color: color,
      side: side.scale(t),
    );
  }

  @override
  PolygonShape copyWith({
    List<Offset>? vertices,
    String? name,
    Color? color,
    BorderSide? side,
  }) {
    return PolygonShape(
      id: id,
      vertices: vertices ?? [...this.vertices],
      name: name ?? this.name,
      color: color ?? this.color,
      side: side ?? this.side,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolygonShape &&
          id == other.id &&
          listEquals<Offset>(vertices, other.vertices) &&
          name == other.name &&
          color == other.color &&
          side == other.side;

  @override
  int get hashCode => Object.hashAll([
        id,
        vertices,
        name,
        color,
        side,
      ]);

  @override
  String toString() => '$runtimeType {name: $name, vertices: $vertices}';
}

extension on double {
  double with1decimal() => double.parse(toStringAsFixed(1));
}
