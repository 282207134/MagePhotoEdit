import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/project_store.dart';
import '../../services/export_service.dart';
import '../../ui/kit.dart';
import '../library/library_screen.dart';
import 'editor_canvas.dart';
import 'editor_model.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.screen,
    required this.store,
    this.document,
    this.chosenAsset,
  });
  final String screen;
  final ProjectStore store;
  final EditorDocument? document;
  final String? chosenAsset;
  @override
  State<EditorScreen> createState() => EditorScreenState();
}

class EditorScreenState extends State<EditorScreen> {
  late final EditorController controller;
  final canvasKey = GlobalKey();
  late final TextEditingController text;
  String mode = '', tab = '', blend = 'Normal';
  bool exporting = false, busy = false, pickingBackground = false;
  String imageQuery = '';
  EditorDocument get doc => controller.document;
  EditorLayer? get layer => controller.layer;
  bool get textMode => mode == 'Text';
  @override
  void initState() {
    super.initState();
    final s = widget.screen;
    controller = EditorController(
      widget.document?.copy() ??
          EditorDocument(title: s == 'New Project' ? 'Untitled' : 'My design'),
    );
    if (widget.document == null) {
      if (s == 'New Project') doc.backgroundMode = 'Transparent';
      if (s.contains('Graphic') || s.contains('Shape')) {
        doc.background = s.contains('Shape') ? 'woman' : 'palms';
      }
      if (s.contains('Text')) doc.background = 'neon-girl';
      if (s == 'Add Image 2' ||
          s == 'Layers' ||
          s.startsWith('Filters') ||
          s == 'Adjust' ||
          s == 'Crop' ||
          s.startsWith('Shadow') ||
          s == 'Opacity' ||
          s.startsWith('Background')) {
        doc.layers.add(EditorLayer(kind: 'image', value: 'hiker'));
        controller.selected = 0;
      }
      if (s == 'Edit Graphic') {
        doc.layers.add(
          EditorLayer(
            kind: 'graphic',
            value: widget.chosenAsset ?? 'summer-sticker',
            width: .8,
          ),
        );
        controller.selected = 0;
      }
      if (s == 'Edit Shape') {
        for (var i = 0; i < 3; i++) {
          doc.layers.add(
            EditorLayer(
              kind: 'shape',
              value: widget.chosenAsset ?? 'shape:11',
              color: 0xffb150d6,
              x: .2 + i * .06,
              y: .3 + i * .16,
              width: .12 + i * .11,
            ),
          );
        }
        controller.selected = 2;
      }
      if (s.contains('Text')) {
        doc.layers.add(
          EditorLayer(
            kind: 'text',
            value: 'PEACE, LOVE\nAND PARTY',
            width: .88,
            rotation: s == 'Edit Template Text Sample' ? -.12 : 0,
          ),
        );
        controller.selected = 0;
      }
      if (s == 'Add Image' || s == 'Background Image') {
        pickingBackground = s == 'Background Image';
        mode = 'Images';
        tab = 'Photos';
        if (s.startsWith('Background')) tab = 'Unsplash';
      }
      if (s == 'Layers') mode = 'Layers';
      if (s.startsWith('Filters')) {
        mode = 'Filters';
        if (s != 'Filters') doc.filter = 'NOIR';
        if (s == 'Filters Intensity') {
          tab = 'Intensity';
          doc.intensity = .5;
        }
      }
      if (s == 'Adjust') {
        mode = 'Adjust';
        tab = 'Exposure';
        doc.exposure = 38;
      }
      if (s == 'Crop') {
        mode = 'Crop';
        tab = 'Original';
      }
      if (s.startsWith('Shadow')) {
        mode = 'Shadow';
        tab = s.substring(7);
        doc.shadowSize = 50;
      }
      if (s == 'Opacity') {
        mode = 'Opacity';
        layer?.opacity = .5;
      }
      if (s.startsWith('Background') && s != 'Background Image') {
        mode = 'Background';
        tab = s.substring(11);
        doc.backgroundMode = tab == 'Color Picker' ? 'Color' : tab;
        if (tab == 'Color Picker') {
          doc.backgroundColor = 0xffb90c55;
          tab = 'Picker';
        }
      }
      if (s.contains('Text') && s != 'Edit Template Text Sample') {
        mode = 'Text';
        tab = s == 'Text Fonts'
            ? 'Fonts'
            : s == 'Text Style'
            ? 'Style'
            : s == 'Text Color Picker'
            ? 'Picker'
            : 'Color';
        if (s == 'Text Fill') {
          layer?.fill = true;
          layer?.color = 0xff00d7d5;
        }
        if (s == 'Text Pick a Color 2') layer?.color = 0xff00d7d5;
        if (s == 'Text Color Picker') layer?.color = 0xffffb72e;
        if (s == 'Text Pick a Color') mode = 'Pick a Color';
      }
    }
    text = TextEditingController(
      text: controller.layer?.kind == 'text'
          ? controller.layer!.value
          : 'PEACE, LOVE\nAND PARTY',
    );
    if (mode.isNotEmpty) {
      controller.beginTransaction();
    }
  }

  @override
  void dispose() {
    text.dispose();
    controller.dispose();
    super.dispose();
  }

  void openPanel(String value, {String? initialTab}) {
    FocusScope.of(context).unfocus();
    controller.beginTransaction();
    setState(() {
      mode = value;
      tab =
          initialTab ??
          switch (value) {
            'Adjust' => 'Exposure',
            'Shadow' => 'Size',
            'Background' => doc.backgroundMode,
            'Images' => 'Photos',
            'Text' => 'Color',
            _ => '',
          };
    });
  }

  void closePanel({bool apply = true}) {
    FocusScope.of(context).unfocus();
    controller.endTransaction(cancel: !apply);
    setState(() {
      mode = '';
      tab = '';
    });
  }

  Future<void> _back() async {
    if (mode.isNotEmpty) {
      closePanel(apply: false);
      return;
    }
    await widget.store.save(doc);
    if (mounted) Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => PopScope(
      canPop: mode.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && mode.isNotEmpty) closePanel(apply: false);
        if (didPop) widget.store.save(doc);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              if (mode.isEmpty)
                _toolbar()
              else
                PageHeader(
                  mode == 'Images'
                      ? 'Images'
                      : mode == 'Text'
                      ? 'Text'
                      : mode,
                  cancel: mode != 'Layers' && mode != 'Images',
                  onBack: mode == 'Pick a Color'
                      ? _returnToText
                      : () => closePanel(apply: false),
                  onDone: mode == 'Images'
                      ? null
                      : mode == 'Pick a Color'
                      ? _returnToText
                      : () => closePanel(),
                ),
              if (mode == 'Images')
                Expanded(child: _images())
              else if (textMode)
                Expanded(child: _textEditor())
              else ...[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: mode.isEmpty ? 0 : 32,
                      vertical: mode.isEmpty ? 5 : 0,
                    ),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: doc.aspect,
                        child: RepaintBoundary(
                          key: canvasKey,
                          child: mode == 'Pick a Color'
                              ? GestureDetector(
                                  onTapUp: (details) =>
                                      _sampleColor(details.localPosition),
                                  child: layerImage(doc.background),
                                )
                              : EditorCanvas(
                                  controller: controller,
                                  handles: !exporting,
                                  crop: mode == 'Crop',
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (mode.isNotEmpty) const SizedBox(height: 28),
                if (mode.isEmpty)
                  _tools()
                else if (mode == 'Pick a Color')
                  _eyedropper()
                else
                  _panel(),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  void _returnToText() => setState(() {
    mode = 'Text';
    tab = 'Color';
  });

  Widget _eyedropper() => Padding(
    padding: const EdgeInsets.fromLTRB(32, 0, 32, 26),
    child: Row(
      children: [
        Icon(Icons.colorize, color: Color(layer?.color ?? 0xffffffff)),
        const SizedBox(width: 12),
        const Expanded(child: Text('Tap the image to sample a color')),
        SizedBox(
          width: 38,
          height: 38,
          child: GestureDetector(
            onTap: _sampleCenterColor,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(layer?.color ?? 0xffffffff),
                border: Border.all(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _sampleCenterColor() async {
    final boundary =
        canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    await _sampleColor(boundary.size.center(Offset.zero));
  }

  Future<void> _sampleColor(Offset position) async {
    final boundary =
        canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage();
    try {
      final data = await image.toByteData();
      if (data == null || !mounted || mode != 'Pick a Color') return;
      final x = position.dx.floor().clamp(0, image.width - 1);
      final y = position.dy.floor().clamp(0, image.height - 1);
      final offset = (y * image.width + x) * 4;
      final color = Color.fromARGB(
        255,
        data.getUint8(offset),
        data.getUint8(offset + 1),
        data.getUint8(offset + 2),
      );
      controller.change(() => layer?.color = color.toARGB32());
    } finally {
      image.dispose();
    }
  }

  Widget _toolbar() => SizedBox(
    height: 70,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Back and save',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_ios_new, size: 23),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Undo',
                onPressed: controller.canUndo ? controller.undo : null,
                icon: const Icon(Icons.undo, size: 24),
              ),
              IconButton(
                tooltip: 'Layers',
                onPressed: () => openPanel('Layers'),
                icon: const Icon(Icons.layers_outlined, size: 25),
              ),
              IconButton(
                tooltip: 'Redo',
                onPressed: controller.canRedo ? controller.redo : null,
                icon: const Icon(Icons.redo, size: 24),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Save and export',
            onPressed: busy ? null : _saveDialog,
            icon: const Icon(Icons.ios_share, size: 24),
          ),
        ],
      ),
    ),
  );
  Widget _tools() {
    final selected = layer != null;
    final labels = selected
        ? layer!.kind == 'text'
              ? ['Text', 'Fonts', 'Style', 'Color', 'Delete']
              : ['Filters', 'Adjust', 'Crop', 'Shadow', 'Opacity', 'Background']
        : ['Image', 'Text', 'Graphic', 'Shape', 'Background'];
    final icons = selected
        ? layer!.kind == 'text'
              ? [
                  Icons.text_fields,
                  Icons.font_download_outlined,
                  Icons.format_align_center,
                  Icons.palette_outlined,
                  Icons.delete_outline,
                ]
              : [
                  Icons.filter_vintage_outlined,
                  Icons.tune,
                  Icons.crop,
                  Icons.blur_on,
                  Icons.opacity,
                  Icons.texture,
                ]
        : [
            Icons.camera_alt_outlined,
            Icons.title,
            Icons.brush_outlined,
            Icons.interests_outlined,
            Icons.texture,
          ];
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        itemBuilder: (_, i) => SizedBox(
          width: selected
              ? 70
              : MediaQuery.sizeOf(context).width.clamp(0, 600) / 5,
          child: InkWell(
            onTap: () => _tool(labels[i]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icons[i], color: muted, size: 24),
                const SizedBox(height: 7),
                Text(
                  labels[i].toUpperCase(),
                  style: const TextStyle(fontSize: 8, color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _tool(String value) {
    if (value == 'Delete') {
      controller.remove();
      return;
    }
    if (value == 'Image') {
      pickingBackground = false;
      openPanel('Images');
      return;
    }
    if (value == 'Text' ||
        value == 'Fonts' ||
        value == 'Style' ||
        value == 'Color') {
      if (layer?.kind != 'text') {
        controller.add(
          EditorLayer(
            kind: 'text',
            value: 'PEACE, LOVE\nAND PARTY',
            width: .88,
          ),
        );
      }
      text.text = layer!.value;
      openPanel('Text', initialTab: value == 'Text' ? 'Color' : value);
      return;
    }
    if (value == 'Graphic' || value == 'Shape') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (c) => LibraryScreen(
            screen: value,
            store: widget.store,
            onSelect: (asset) {
              Navigator.pop(c);
              controller.add(
                EditorLayer(
                  kind: value == 'Shape' ? 'shape' : 'graphic',
                  value: asset,
                  width: value == 'Shape' ? 0.35 : .8,
                  color: value == 'Shape' ? 0xffb150d6 : 0xffffffff,
                ),
              );
            },
          ),
        ),
      );
      return;
    }
    openPanel(value);
  }

  Widget _panel() => Container(
    height: 220,
    decoration: const BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      children: [
        if (mode != 'Filters' || tab == 'Intensity')
          SizedBox(
            height: 58,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Cancel changes',
                  onPressed: () => closePanel(apply: false),
                  icon: const Icon(Icons.close, color: muted, size: 22),
                ),
                Expanded(
                  child: Text(
                    _panelTitle(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                IconButton(
                  tooltip: 'Apply changes',
                  onPressed: () => closePanel(),
                  icon: const Icon(Icons.check, color: muted, size: 24),
                ),
              ],
            ),
          ),
        Expanded(
          child: switch (mode) {
            'Filters' => _filters(),
            'Adjust' => _adjust(),
            'Shadow' => _shadow(),
            'Opacity' => _opacity(),
            'Background' => _background(),
            'Crop' => _crop(),
            'Layers' => _layers(),
            _ => const SizedBox(),
          },
        ),
      ],
    ),
  );
  String _panelTitle() => switch (mode) {
    'Adjust' => '$tab ${_adjustValue().round()}',
    'Shadow' =>
      tab == 'Color'
          ? 'Color'
          : tab == 'Opacity'
          ? 'Opacity ${(doc.shadowOpacity * 100).round()}%'
          : '$tab ${_shadowValue().round()}${tab == 'Angle' ? '°' : ''}',
    'Opacity' => 'Opacity ${((layer?.opacity ?? 1) * 100).round()}%',
    'Filters' => 'Intensity ${(doc.intensity * 100).round()}%',
    'Background' => tab == 'Picker' ? 'Color' : tab,
    'Layers' => 'Layers',
    _ => mode,
  };
  Widget _filters() {
    if (tab == 'Intensity') {
      return Column(
        children: [
          _slider(doc.intensity, 0, 1, (v) => doc.intensity = v),
          const Spacer(),
          _blendStrip(),
          const SizedBox(height: 15),
        ],
      );
    }
    return Column(
      children: [
        const SizedBox(height: 22),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, i) => const SizedBox(width: 16),
            itemBuilder: (_, i) {
              final name = ['NORMAL', 'NOIR', 'MONO', 'INSTANT'][i];
              return InkWell(
                onTap: () {
                  if (doc.filter == name) {
                    setState(() => tab = 'Intensity');
                  } else {
                    controller.change(() => doc.filter = name);
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: doc.filter == name ? pink : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: ColorFiltered(
                          colorFilter: documentFilter(doc, preset: name),
                          child: layerImage(
                            layer?.kind == 'image' ? layer!.value : 'hiker',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 9,
                        color: doc.filter == name ? pink : muted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Spacer(),
        _blendStrip(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _blendStrip() => ChoiceStrip(
    const ['Normal', 'Darken', 'Multiply', 'Color Burn', 'Lighten'],
    small: true,
    padding: 20,
    selected: blend,
    onSelected: (v) {
      setState(() => blend = v);
      controller.change(
        () => doc.contrast = v == 'Darken'
            ? 25
            : v == 'Multiply'
            ? 40
            : v == 'Color Burn'
            ? 65
            : 0,
      );
    },
  );
  double _adjustValue() => switch (tab) {
    'Contrast' => doc.contrast,
    'Saturation' => doc.saturation,
    'Warmth' => doc.warmth,
    _ => doc.exposure,
  };
  Widget _adjust() => Column(
    children: [
      _slider(_adjustValue(), -100, 100, (v) {
        switch (tab) {
          case 'Contrast':
            doc.contrast = v;
          case 'Saturation':
            doc.saturation = v;
          case 'Warmth':
            doc.warmth = v;
          default:
            doc.exposure = v;
        }
      }),
      const Spacer(),
      ChoiceStrip(
        const ['Exposure', 'Contrast', 'Saturation', 'Warmth'],
        small: true,
        padding: 20,
        selected: tab,
        onSelected: (v) => setState(() => tab = v),
      ),
      const SizedBox(height: 16),
    ],
  );
  double _shadowValue() => switch (tab) {
    'Angle' => doc.shadowAngle,
    'Blur' => doc.shadowBlur,
    'Opacity' => doc.shadowOpacity,
    _ => doc.shadowSize,
  };
  Widget _shadow() => Column(
    children: [
      if (tab == 'Color')
        _colors(Color(doc.shadowColor), (c) => doc.shadowColor = c.toARGB32())
      else
        _slider(
          _shadowValue(),
          0,
          tab == 'Angle'
              ? 360
              : tab == 'Opacity'
              ? 1
              : 100,
          (v) {
            switch (tab) {
              case 'Angle':
                doc.shadowAngle = v;
              case 'Blur':
                doc.shadowBlur = v;
              case 'Opacity':
                doc.shadowOpacity = v;
              default:
                doc.shadowSize = v;
            }
          },
        ),
      const Spacer(),
      ChoiceStrip(
        const ['Size', 'Angle', 'Blur', 'Color', 'Opacity'],
        small: true,
        padding: 20,
        selected: tab,
        onSelected: (v) => setState(() => tab = v),
      ),
      const SizedBox(height: 16),
    ],
  );
  Widget _opacity() => Column(
    children: [
      _slider(layer?.opacity ?? 1, 0, 1, (v) => layer?.opacity = v),
      const Spacer(),
      _blendStrip(),
      const SizedBox(height: 16),
    ],
  );
  Widget _background() => Column(
    children: [
      if (tab == 'Picker')
        _colorPicker(Color(doc.backgroundColor), (c) {
          doc.backgroundColor = c.toARGB32();
          doc.backgroundMode = 'Color';
        })
      else if (tab == 'Transparent')
        SizedBox(
          height: 56,
          child: Center(
            child: Text(
              'Transparent Background',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
        )
      else if (tab == 'Gradient' || tab == 'Pastel')
        _colors(
          Color(doc.backgroundColor),
          (c) {
            doc.backgroundColor = c.toARGB32();
            doc.backgroundMode = tab;
          },
          gradient: true,
          pastel: tab == 'Pastel',
        )
      else
        _colors(Color(doc.backgroundColor), (c) {
          doc.backgroundColor = c.toARGB32();
          doc.backgroundMode = 'Color';
        }),
      const Spacer(),
      ChoiceStrip(
        const ['Image', 'Transparent', 'Color', 'Gradient', 'Pastel', 'Picker'],
        small: true,
        padding: 20,
        selected: tab,
        onSelected: (v) {
          if (v == 'Image') {
            pickingBackground = true;
            setState(() {
              mode = 'Images';
              tab = 'Unsplash';
            });
            return;
          }
          setState(() => tab = v);
          controller.change(
            () => doc.backgroundMode = v == 'Picker' ? 'Color' : v,
          );
        },
      ),
      const SizedBox(height: 16),
    ],
  );
  Widget _crop() => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Rotate left',
            onPressed: () => controller.change(() => layer?.rotation -= 1.5708),
            icon: const Icon(Icons.rotate_90_degrees_ccw),
          ),
          IconButton(
            tooltip: 'Rotate right',
            onPressed: () => controller.change(() => layer?.rotation += 1.5708),
            icon: const Icon(Icons.rotate_90_degrees_cw),
          ),
          TextButton(
            onPressed: () {
              setState(() => tab = 'Original');
              controller.change(() {
                doc.aspect = .69;
                doc.circleCrop = false;
              });
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      if (tab == 'Custom') _slider(doc.aspect, .5, 2, (v) => doc.aspect = v),
      const Spacer(),
      ChoiceStrip(
        const ['Original', 'Custom', 'Square', 'Circle', '3:4', '4:3', '16:9'],
        small: true,
        padding: 20,
        selected: tab,
        onSelected: (v) {
          setState(() => tab = v);
          controller.change(() {
            doc.circleCrop = v == 'Circle';
            doc.aspect = switch (v) {
              'Square' || 'Circle' => 1,
              '3:4' => .75,
              '4:3' => 4 / 3,
              '16:9' => 16 / 9,
              'Custom' => doc.aspect,
              _ => .69,
            };
          });
        },
      ),
      const SizedBox(height: 16),
    ],
  );
  Widget _layers() => Column(
    children: [
      Expanded(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: doc.layers.length + 1,
          separatorBuilder: (_, i) => const SizedBox(width: 16),
          itemBuilder: (_, i) {
            final l = i == 0 ? null : doc.layers[i - 1];
            final active = controller.selected == i - 1;
            return InkWell(
              onTap: () => controller.select(i - 1),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active ? pink : Colors.transparent,
                      ),
                    ),
                    child: l == null
                        ? layerImage(doc.background)
                        : l.kind == 'image' || l.kind == 'graphic'
                        ? layerImage(l.value)
                        : Icon(
                            l.kind == 'shape'
                                ? shapeIcon(l.value)
                                : Icons.text_fields,
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i == 0 ? 'BACKGROUND' : 'LAYER $i',
                    style: TextStyle(fontSize: 9, color: active ? pink : muted),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _saveDialog,
              child: const Text(
                'Share',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: layer == null
                  ? null
                  : () =>
                        controller.change(() => layer!.hidden = !layer!.hidden),
              child: Text(
                layer?.hidden == true ? 'Show' : 'Hide',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: layer == null
                  ? null
                  : () =>
                        controller.change(() => layer!.locked = !layer!.locked),
              child: Text(
                layer?.locked == true ? 'Unlock' : 'Lock',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: layer == null ? null : controller.remove,
              child: const Text(
                'Delete',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _slider(
    double value,
    double min,
    double max,
    ValueChanged<double> change,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Slider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      onChangeStart: (_) => controller.checkpoint(),
      onChanged: (v) => controller.change(() => change(v), record: false),
    ),
  );
  Widget _colors(
    Color current,
    ValueChanged<Color> change, {
    bool gradient = false,
    bool pastel = false,
  }) => SizedBox(
    height: 62,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: palette.length + 2,
      separatorBuilder: (_, i) => const SizedBox(width: 15),
      itemBuilder: (_, i) {
        if (i == 0) {
          return IconButton(
            tooltip: 'Pick a color',
            onPressed: () => setState(() {
              if (mode == 'Text') {
                mode = 'Pick a Color';
              } else {
                tab = 'Picker';
              }
            }),
            icon: const Icon(Icons.colorize, color: muted),
          );
        }
        if (i == 1) {
          return IconButton(
            tooltip: 'No fill',
            onPressed: () => controller.change(() {
              if (mode == 'Text') {
                layer?.fill = false;
              } else {
                doc.backgroundMode = 'Transparent';
              }
            }),
            icon: const Icon(Icons.block, color: muted),
          );
        }
        final c = pastel
            ? Color.lerp(palette[i - 2], Colors.white, .7)!
            : palette[i - 2];
        return Center(
          child: InkWell(
            onTap: () => controller.change(() => change(c)),
            child: Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: current == c ? Colors.white : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gradient ? null : c,
                  gradient: gradient
                      ? LinearGradient(colors: [c, const Color(0xff565de6)])
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
  Widget _colorPicker(Color color, ValueChanged<Color> change) {
    final hsv = HSVColor.fromColor(color);
    return SizedBox(
      height: 102,
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            SizedBox(
              height: 30,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: i == 0
                          ? const [
                              Colors.red,
                              Colors.yellow,
                              Colors.green,
                              Colors.cyan,
                              Colors.blue,
                              Colors.purple,
                              Colors.red,
                            ]
                          : i == 1
                          ? [Colors.white, color]
                          : [Colors.transparent, color],
                    ),
                  ),
                  child: Slider(
                    value: i == 0
                        ? hsv.hue
                        : i == 1
                        ? hsv.saturation
                        : color.a,
                    min: 0,
                    max: i == 0 ? 360 : 1,
                    onChangeStart: (_) => controller.checkpoint(),
                    onChanged: (v) => controller.change(
                      () => change(
                        i == 0
                            ? hsv.withHue(v).toColor()
                            : i == 1
                            ? hsv.withSaturation(v).toColor()
                            : color.withValues(alpha: v),
                      ),
                      record: false,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _textEditor() => Column(
    children: [
      ChoiceStrip(
        const ['Color', 'Fonts', 'Style'],
        selected: ['Picker', 'Fill'].contains(tab) ? 'Color' : tab,
        onSelected: (v) => setState(() => tab = v),
        padding: 75,
      ),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: text,
              maxLines: null,
              textAlign: layer?.align == 'Left'
                  ? TextAlign.left
                  : layer?.align == 'Right'
                  ? TextAlign.right
                  : TextAlign.center,
              style: TextStyle(
                fontFamily: layer?.font,
                color: layer?.fill == true
                    ? Colors.white
                    : Color(layer?.color ?? 0xffffffff),
                backgroundColor: layer?.fill == true
                    ? Color(layer!.color)
                    : null,
                fontSize: 36,
                fontWeight: layer?.bold == true
                    ? FontWeight.w900
                    : FontWeight.w400,
                fontStyle: layer?.italic == true
                    ? FontStyle.italic
                    : FontStyle.normal,
                letterSpacing: layer?.spacing ?? 0,
                height: layer?.lineHeight ?? 1.1,
              ),
              decoration: const InputDecoration(border: InputBorder.none),
              onChanged: (v) =>
                  controller.change(() => layer?.value = v, record: false),
            ),
          ),
        ),
      ),
      if (tab == 'Fonts')
        _fonts()
      else if (tab == 'Style')
        _textStyle()
      else if (tab == 'Picker')
        Container(
          color: panel,
          padding: const EdgeInsets.only(top: 10, bottom: 12),
          child: _colorPicker(
            Color(layer?.color ?? 0xffffb72e),
            (c) => layer?.color = c.toARGB32(),
          ),
        )
      else
        _colors(
          Color(layer?.color ?? 0xffffffff),
          (c) => layer?.color = c.toARGB32(),
        ),
      if (tab == 'Color' || tab == 'Fill')
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => controller.change(() => layer?.fill = false),
                child: Text(
                  'Text color',
                  style: TextStyle(color: layer?.fill == false ? pink : muted),
                ),
              ),
              TextButton(
                onPressed: () => controller.change(() => layer?.fill = true),
                child: Text(
                  'Fill',
                  style: TextStyle(color: layer?.fill == true ? pink : muted),
                ),
              ),
              IconButton(
                tooltip: 'Color picker',
                onPressed: () => setState(() => tab = 'Picker'),
                icon: const Icon(Icons.palette_outlined),
              ),
            ],
          ),
        ),
    ],
  );
  Widget _fonts() => Container(
    height: 260,
    decoration: const BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final f in [
          'Noto Sans',
          'Oxanium',
          'Patua One',
          'Bangers',
          'Montserrat',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => controller.change(() => layer?.font = f),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xff4b4b50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: layer?.font == f ? pink : Colors.transparent,
                  ),
                ),
                child: Text(f, style: TextStyle(fontFamily: f, fontSize: 19)),
              ),
            ),
          ),
      ],
    ),
  );
  Widget _textStyle() => Container(
    height: 260,
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Alignment',
              style: TextStyle(fontSize: 11, color: muted),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Bold',
              onPressed: () => controller.change(
                () => layer?.bold = !(layer?.bold ?? false),
              ),
              icon: Icon(
                Icons.format_bold,
                color: layer?.bold == true ? pink : muted,
              ),
            ),
            IconButton(
              tooltip: 'Italic',
              onPressed: () => controller.change(
                () => layer?.italic = !(layer?.italic ?? false),
              ),
              icon: Icon(
                Icons.format_italic,
                color: layer?.italic == true ? pink : muted,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 34,
          child: ChoiceStrip(
            const ['Left', 'Center', 'Right'],
            selected: layer?.align ?? 'Center',
            onSelected: (v) => controller.change(() => layer?.align = v),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Letter Spacing',
          style: TextStyle(fontSize: 10, color: muted),
        ),
        _slider(layer?.spacing ?? 0, 0, 10, (v) => layer?.spacing = v),
        const Text(
          'Line Spacing',
          style: TextStyle(fontSize: 10, color: muted),
        ),
        _slider(layer?.lineHeight ?? 1.1, .8, 2, (v) => layer?.lineHeight = v),
      ],
    ),
  );
  Widget _images() {
    const photos = [
      'car',
      'metal',
      'flamingo-photo',
      'color-wave',
      'leaves',
      'hiker',
    ];
    const unsplash = ['city', 'dunes', 'vibes', 'abstract', 'powder', 'palms'];
    final assets = (tab == 'Photos' ? photos : unsplash)
        .where((v) => v.contains(imageQuery.toLowerCase().trim()))
        .toList();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        ChoiceStrip(
          const ['Photos', 'Unsplash', 'Pixabay'],
          selected: tab,
          onSelected: (v) => setState(() {
            tab = v;
            imageQuery = '';
          }),
        ),
        const SizedBox(height: 22),
        if (tab == 'Photos')
          OutlinedButton.icon(
            onPressed: _importImage,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 19),
            label: const Text(
              'Choose from device',
              style: TextStyle(fontSize: 12),
            ),
          )
        else
          SearchBox(
            hint: 'Search Free Photos',
            onChanged: (v) => setState(() => imageQuery = v),
          ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var col = 0; col < 2; col++) ...[
              if (col == 1) const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (var i = col; i < assets.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            if (pickingBackground) {
                              controller.change(() {
                                doc.background = assets[i];
                                doc.backgroundMode = 'Image';
                              });
                            } else {
                              controller.add(
                                EditorLayer(kind: 'image', value: assets[i]),
                              );
                            }
                            closePanel();
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: art(
                              assets[i],
                              height: i % 3 == 0 ? 220 : 160,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _importImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 2000,
        imageQuality: 88,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 12 * 1024 * 1024) {
        if (mounted) tell(context, 'Choose an image smaller than 12 MB.');
        return;
      }
      if (pickingBackground) {
        controller.change(() {
          doc.background = 'data:${base64Encode(bytes)}';
          doc.backgroundMode = 'Image';
        });
      } else {
        controller.add(
          EditorLayer(kind: 'image', value: 'data:${base64Encode(bytes)}'),
        );
      }
      closePanel();
    } catch (e) {
      if (mounted) {
        tell(context, 'Could not open the photo picker. Please try again.');
      }
    }
  }

  Future<void> _saveDialog() async {
    final title = TextEditingController(text: doc.title);
    var folder = doc.folder;
    final action = await showDialog<String>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          title: const Text('Save your design'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Project name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: widget.store.folders.contains(folder)
                    ? folder
                    : widget.store.folders.first,
                decoration: const InputDecoration(labelText: 'Folder'),
                items: widget.store.folders
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => update(() => folder = v ?? folder),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, 'save'),
              child: const Text('Save draft'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, 'export'),
              child: const Text('Export PNG'),
            ),
          ],
        ),
      ),
    );
    if (action != null) {
      doc.title = title.text.trim().isEmpty ? 'Untitled' : title.text.trim();
      doc.folder = folder;
      await widget.store.save(doc);
      if (mounted) {
        if (action == 'export') {
          await exportPng();
        } else {
          tell(context, 'Project saved');
        }
      }
    }
    title.dispose();
  }

  Future<String?> exportPng() async {
    if (busy) return null;
    try {
      FocusScope.of(context).unfocus();
      setState(() {
        busy = true;
        exporting = true;
        mode = '';
      });
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          canvasKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final path = await savePng(
        data!.buffer.asUint8List(),
        'mage-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      if (mounted) tell(context, 'PNG saved: $path');
      return path;
    } catch (e) {
      if (mounted) tell(context, 'Export failed. Please try again.');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          exporting = false;
        });
      }
    }
  }
}
