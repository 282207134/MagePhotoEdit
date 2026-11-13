import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/kit.dart';
import 'editor_model.dart';

Widget layerImage(String value, {BoxFit fit = BoxFit.cover}) =>
    value.startsWith('data:')
    ? Image.memory(
        base64Decode(value.substring(5)),
        fit: fit,
        gaplessPlayback: true,
      )
    : art(value, fit: fit);

ColorFilter documentFilter(EditorDocument d, {String? preset}) {
  final filter = preset ?? d.filter;
  final mono = filter == 'NOIR' || filter == 'MONO';
  final instant = filter == 'INSTANT' ? d.intensity : 0.0;
  final sat =
      (1 + d.saturation / 100) * (mono ? 1 - d.intensity : 1 - instant * .3);
  final c = 1 + d.contrast / 100 - instant * .15;
  final e = d.exposure * 1.4 - (c - 1) * 128;
  final warm = d.warmth * .5 + instant * 20;
  final r = .2126 * (1 - sat), g = .7152 * (1 - sat), b = .0722 * (1 - sat);
  final noir = filter == 'NOIR' ? 1 - d.intensity * .33 : 1.0;
  return ColorFilter.matrix([
    (r + sat) * c * noir,
    g * c * noir,
    b * c * noir,
    0,
    e + warm,
    r * c * noir,
    (g + sat) * c * noir,
    b * c * noir,
    0,
    e,
    r * c * noir,
    g * c * noir,
    (b + sat) * c * noir,
    0,
    e - warm,
    0,
    0,
    0,
    1,
    0,
  ]);
}

class EditorCanvas extends StatelessWidget {
  const EditorCanvas({
    super.key,
    required this.controller,
    this.handles = true,
    this.crop = false,
  });
  final EditorController controller;
  final bool handles, crop;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final d = controller.document;
      final content = ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (handles) const Checkerboard(),
            if (d.backgroundMode == 'Image') layerImage(d.background),
            if (d.backgroundMode == 'Color')
              ColoredBox(color: Color(d.backgroundColor)),
            if (d.backgroundMode == 'Gradient' || d.backgroundMode == 'Pastel')
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: d.backgroundMode == 'Pastel'
                        ? const [Color(0xffa49bd9), Color(0xfff9ceca)]
                        : [Color(d.backgroundColor), const Color(0xff465ade)],
                  ),
                ),
              ),
            for (var i = 0; i < d.layers.length; i++)
              if (!d.layers[i].hidden) _layer(d.layers[i], i, box.biggest),
            if (crop)
              const Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: _CropGrid())),
              ),
          ],
        ),
      );
      return GestureDetector(
        onTap: handles ? () => controller.select(-1) : null,
        child: d.circleCrop ? ClipOval(child: content) : content,
      );
    },
  );
  Widget _layer(EditorLayer layer, int index, Size size) {
    final d = controller.document;
    final width = size.width * layer.width;
    final isText = layer.kind == 'text', isShape = layer.kind == 'shape';
    final height = isText
        ? width * .42
        : isShape
        ? width
        : width / ((layer.kind == 'image') ? 0.666 : 1.05);
    Widget content;
    if (isText) {
      content = Container(
        alignment: Alignment.center,
        color: layer.fill ? Color(layer.color) : Colors.transparent,
        child: Text(
          layer.value,
          textAlign: layer.align == 'Left'
              ? TextAlign.left
              : layer.align == 'Right'
              ? TextAlign.right
              : TextAlign.center,
          style: TextStyle(
            fontFamily: layer.font,
            fontSize: width / 10,
            fontWeight: layer.bold ? FontWeight.w900 : FontWeight.w400,
            fontStyle: layer.italic ? FontStyle.italic : FontStyle.normal,
            color: layer.fill ? Colors.white : Color(layer.color),
            height: layer.lineHeight,
            letterSpacing: layer.spacing,
          ),
        ),
      );
    } else if (isShape) {
      content = Icon(
        shapeIcon(layer.value),
        color: Color(layer.color),
        size: width,
      );
    } else {
      content = ColorFiltered(
        colorFilter: documentFilter(d),
        child: layerImage(
          layer.value,
          fit: layer.kind == 'graphic' ? BoxFit.contain : BoxFit.cover,
        ),
      );
    }
    content = Opacity(opacity: layer.opacity.clamp(0, 1), child: content);
    if (d.shadowSize > 0) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(d.shadowColor).withValues(alpha: d.shadowOpacity),
              blurRadius: d.shadowBlur,
              offset: Offset(
                math.cos(d.shadowAngle * math.pi / 180) * d.shadowSize,
                math.sin(d.shadowAngle * math.pi / 180) * d.shadowSize,
              ),
            ),
          ],
        ),
        child: content,
      );
    }
    if (handles && controller.selected == index) {
      content = SelectionBorder(child: content);
    }
    return Positioned(
      left: layer.x * size.width - width / 2,
      top: layer.y * size.height - height / 2,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: layer.rotation,
        child: GestureDetector(
          onTap: handles ? () => controller.select(index) : null,
          onScaleStart: handles && !layer.locked
              ? (_) {
                  controller.checkpoint();
                  _scaleStart[layer] = layer.width;
                  _rotationStart[layer] = layer.rotation;
                }
              : null,
          onScaleUpdate: handles && !layer.locked
              ? (details) => controller.change(() {
                  layer.x = (layer.x + details.focalPointDelta.dx / size.width)
                      .clamp(0, 1);
                  layer.y = (layer.y + details.focalPointDelta.dy / size.height)
                      .clamp(0, 1);
                  layer.width =
                      ((_scaleStart[layer] ?? layer.width) * details.scale)
                          .clamp(.1, 1.5);
                  layer.rotation =
                      (_rotationStart[layer] ?? 0) + details.rotation;
                }, record: false)
              : null,
          child: content,
        ),
      ),
    );
  }
}

final _scaleStart = Expando<double>();
final _rotationStart = Expando<double>();
IconData shapeIcon(String value) {
  final n = int.tryParse(value.replaceFirst('shape:', '')) ?? 0;
  return [
    Icons.star,
    Icons.star_rounded,
    Icons.hexagon,
    Icons.change_history,
    Icons.signal_cellular_4_bar,
    Icons.square,
    Icons.hexagon,
    Icons.hexagon_rounded,
    Icons.diamond,
    Icons.stop_rounded,
    Icons.stop,
    Icons.favorite,
    Icons.favorite,
    Icons.favorite,
    Icons.favorite,
  ][n % 15];
}

class _CropGrid extends CustomPainter {
  const _CropGrid();
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      c.drawLine(
        Offset(s.width * i / 3, 0),
        Offset(s.width * i / 3, s.height),
        p,
      );
      c.drawLine(
        Offset(0, s.height * i / 3),
        Offset(s.width, s.height * i / 3),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
