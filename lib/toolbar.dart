import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'enumdart';

const _kElevation = 4.0;
const _kButtonSize = 32.0;
const _kIconSize = 20.0;

class LocationZoneFloorPlanToolbar extends StatefulWidget {
  const LocationZoneFloorPlanToolbar({
    super.key,
    this.initialPaintingTool = PaintingTool.scrolling,
    this.onLayerChange,
    this.onPaintingToolChange,
    this.onZoomIn,
    this.onZoomOut,
    this.onFitToSpace,
  });

  final PaintingTool initialPaintingTool;
  final ValueChanged<int>? onLayerChange;
  final ValueChanged<PaintingTool>? onPaintingToolChange;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onFitToSpace;

  @override
  State<LocationZoneFloorPlanToolbar> createState() =>
      _LocationZoneFloorPlanToolbarState();
}

class _LocationZoneFloorPlanToolbarState
    extends State<LocationZoneFloorPlanToolbar> {
  late final ValueNotifier<List<bool>> _paintingToolsState;

  @override
  void dispose() {
    _paintingToolsState.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _paintingToolsState = ValueNotifier(PaintingTool.values
        .map((paintingTool) => paintingTool == widget.initialPaintingTool)
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (widget.onPaintingToolChange != null)
          Material(
            type: MaterialType.button,
            color: theme.colorScheme.background,
            elevation: _kElevation,
            child: Container(
              width: _kButtonSize,
              height: _kButtonSize * PaintingTool.values.length,
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
              ),
              child: ToggleButtonsTheme(
                data: ToggleButtonsThemeData(
                  color: theme.iconTheme.color,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: ValueListenableBuilder(
                  valueListenable: _paintingToolsState,
                  builder: (context, paintingTools, child) {
                    return ToggleButtons(
                      constraints: BoxConstraints.tight(
                        const Size.square(_kButtonSize),
                      ),
                      direction: Axis.vertical,
                      renderBorder: false,
                      isSelected: paintingTools,
                      onPressed: _onPaintingToolChange,
                      children: const [
                        Tooltip(
                          message: 'Scroll floor plan',
                          child: Icon(MdiIcons.cursorDefaultOutline,
                              size: _kIconSize),
                        ),
                        Tooltip(
                          message: 'Select shapes',
                          child: Icon(MdiIcons.selectDrag, size: _kIconSize),
                        ),
                        Tooltip(
                          message: 'Create shapes',
                          child: Icon(Icons.draw, size: _kIconSize),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onPaintingToolChange(int index) {
    _paintingToolsState.value = PaintingTool.values
        .map((paintingTool) => paintingTool.index == index)
        .toList();
    widget.onPaintingToolChange!(PaintingTool.values[index]);
  }
}
