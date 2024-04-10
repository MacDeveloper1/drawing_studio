import 'package:drawing_studio/enumdart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'paint_studio.dart';
import 'shape.dart';
import 'toolbar.dart';

const _kPadding = 8.0;
const _imageSize = Size(784, 709);

class ZoneFloorPlan extends StatefulWidget {
  const ZoneFloorPlan({super.key});

  @override
  State<ZoneFloorPlan> createState() => _ZoneFloorPlanState();
}

class _ZoneFloorPlanState extends State<ZoneFloorPlan>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final ShapePaintingController _paintingController;

  @override
  void dispose() {
    _transformationController.dispose();
    _paintingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _paintingController = _initPaintingController();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = _getScalingSize(constraints, 1);
        if (kDebugMode) {
          print(imageSize);
        }
        return ListenableBuilder(
          listenable: _paintingController,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: SizedBox(
                    width: imageSize.width,
                    height: imageSize.height,
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 10,
                      scaleEnabled: false,
                      transformationController: _transformationController,
                      child: Stack(
                        children: [
                          Image.network(
                            'https://images.edrawmax.com/examples/apartment-floor-plan/example4.png',
                            isAntiAlias: true,
                            gaplessPlayback: true,
                            fit: BoxFit.contain,
                            alignment: Alignment.topLeft,
                            filterQuality: FilterQuality.high,
                          ),
                          ShapePaintingStudio(
                            controller: _paintingController,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: _kPadding,
                  top: _kPadding,
                  child: LocationZoneFloorPlanToolbar(
                    initialPaintingTool: PaintingTool.drawing,
                    onPaintingToolChange: (tool) {
                      _paintingController.updatePaintingTool(tool);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  ShapePaintingController _initPaintingController() {
    final savedShapes =
        List<Map<String, dynamic>>.from([]).map(PolygonShape.fromJson).toList();
    return ShapePaintingController(
      state: ZonesPaintingState(
        paintingTool: PaintingTool.drawing,
        shapes: savedShapes,
        selectedShapes: const <PolygonShape>[],
      ),
    );
  }

  Size _getScalingSize(BoxConstraints constraints, double scale) {
    final initialImageSize = _getImageInitialSize(constraints, _imageSize);
    final currentImageSize = initialImageSize * scale;
    return currentImageSize;
  }

  Size _getImageInitialSize(BoxConstraints constraints, Size originSize) {
    final inscribedImageConstraints =
        constraints.constrainSizeAndAttemptToPreserveAspectRatio(originSize);
    // Calculate the exact size of inscribed image.
    var inscribedImageSize = Size(
        inscribedImageConstraints.shortestSide * originSize.aspectRatio,
        inscribedImageConstraints.shortestSide);
    if (inscribedImageConstraints.aspectRatio < 1) {
      inscribedImageSize = inscribedImageSize.flipped;
    }
    return inscribedImageSize;
  }
}
