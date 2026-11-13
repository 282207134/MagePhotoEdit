import 'dart:convert';

import 'package:flutter/material.dart';

class EditorLayer {
  EditorLayer({
    required this.kind,
    required this.value,
    this.x = .5,
    this.y = .5,
    this.width = .53,
    this.opacity = 1,
    this.color = 0xffffffff,
    this.hidden = false,
    this.locked = false,
    this.rotation = 0,
    this.font = 'Montserrat',
    this.bold = true,
    this.italic = true,
    this.align = 'Center',
    this.spacing = 0,
    this.lineHeight = 1.1,
    this.fill = false,
  });
  String kind, value, font, align;
  double x, y, width, opacity, rotation, spacing, lineHeight;
  int color;
  bool hidden, locked, bold, italic, fill;
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'value': value,
    'x': x,
    'y': y,
    'width': width,
    'opacity': opacity,
    'color': color,
    'hidden': hidden,
    'locked': locked,
    'rotation': rotation,
    'font': font,
    'bold': bold,
    'italic': italic,
    'align': align,
    'spacing': spacing,
    'lineHeight': lineHeight,
    'fill': fill,
  };
  factory EditorLayer.fromJson(Map<String, dynamic> j) => EditorLayer(
    kind: j['kind'],
    value: j['value'],
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    width: (j['width'] as num).toDouble(),
    opacity: (j['opacity'] as num).toDouble(),
    color: j['color'],
    hidden: j['hidden'],
    locked: j['locked'],
    rotation: (j['rotation'] as num).toDouble(),
    font: j['font'] ?? 'Montserrat',
    bold: j['bold'] ?? true,
    italic: j['italic'] ?? true,
    align: j['align'] ?? 'Center',
    spacing: (j['spacing'] as num? ?? 0).toDouble(),
    lineHeight: (j['lineHeight'] as num? ?? 1.1).toDouble(),
    fill: j['fill'] ?? false,
  );
}

class EditorDocument {
  EditorDocument({
    String? id,
    this.title = 'Untitled',
    this.background = 'poster',
    this.backgroundColor = 0xffff0566,
    this.backgroundMode = 'Image',
    this.filter = 'NORMAL',
    this.intensity = 1,
    this.exposure = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.warmth = 0,
    this.shadowSize = 0,
    this.shadowAngle = 140,
    this.shadowBlur = 20,
    this.shadowOpacity = .5,
    this.shadowColor = 0xff000000,
    this.aspect = .69,
    this.circleCrop = false,
    List<EditorLayer>? layers,
    this.folder = 'Nice Photos',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       layers = layers ?? [];
  final String id;
  String title, background, backgroundMode, filter, folder;
  int backgroundColor, shadowColor;
  bool circleCrop;
  double intensity,
      exposure,
      contrast,
      saturation,
      warmth,
      shadowSize,
      shadowAngle,
      shadowBlur,
      shadowOpacity,
      aspect;
  List<EditorLayer> layers;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'background': background,
    'backgroundColor': backgroundColor,
    'backgroundMode': backgroundMode,
    'filter': filter,
    'intensity': intensity,
    'exposure': exposure,
    'contrast': contrast,
    'saturation': saturation,
    'warmth': warmth,
    'shadowSize': shadowSize,
    'shadowAngle': shadowAngle,
    'shadowBlur': shadowBlur,
    'shadowOpacity': shadowOpacity,
    'shadowColor': shadowColor,
    'aspect': aspect,
    'circleCrop': circleCrop,
    'folder': folder,
    'layers': layers.map((l) => l.toJson()).toList(),
  };
  factory EditorDocument.fromJson(Map<String, dynamic> j) => EditorDocument(
    id: j['id'],
    title: j['title'],
    background: j['background'],
    backgroundColor: j['backgroundColor'],
    backgroundMode: j['backgroundMode'],
    filter: j['filter'],
    intensity: (j['intensity'] as num).toDouble(),
    exposure: (j['exposure'] as num).toDouble(),
    contrast: (j['contrast'] as num).toDouble(),
    saturation: (j['saturation'] as num).toDouble(),
    warmth: (j['warmth'] as num).toDouble(),
    shadowSize: (j['shadowSize'] as num).toDouble(),
    shadowAngle: (j['shadowAngle'] as num).toDouble(),
    shadowBlur: (j['shadowBlur'] as num).toDouble(),
    shadowOpacity: (j['shadowOpacity'] as num).toDouble(),
    shadowColor: j['shadowColor'],
    aspect: (j['aspect'] as num).toDouble(),
    circleCrop: j['circleCrop'] ?? false,
    folder: j['folder'] ?? 'Nice Photos',
    layers: (j['layers'] as List)
        .map((l) => EditorLayer.fromJson(Map<String, dynamic>.from(l)))
        .toList(),
  );
  EditorDocument copy() =>
      EditorDocument.fromJson(jsonDecode(jsonEncode(toJson())));
}

class EditorController extends ChangeNotifier {
  EditorController(this.document);
  EditorDocument document;
  int selected = -1;
  final List<EditorDocument> _past = [], _future = [];
  EditorDocument? _transaction;
  List<EditorDocument>? _transactionPast, _transactionFuture;
  void beginTransaction() {
    _transaction = document.copy();
    _transactionPast = List.of(_past);
    _transactionFuture = List.of(_future);
    checkpoint();
  }

  void endTransaction({bool cancel = false}) {
    if (cancel && _transaction != null) {
      document = _transaction!.copy();
      _past
        ..clear()
        ..addAll(_transactionPast!);
      _future
        ..clear()
        ..addAll(_transactionFuture!);
      notifyListeners();
    }
    _transaction = null;
    _transactionPast = null;
    _transactionFuture = null;
  }

  EditorLayer? get layer => selected >= 0 && selected < document.layers.length
      ? document.layers[selected]
      : null;
  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  void checkpoint() {
    _past.add(document.copy());
    if (_past.length > 40) _past.removeAt(0);
    _future.clear();
  }

  void change(VoidCallback action, {bool record = true}) {
    if (record) checkpoint();
    action();
    notifyListeners();
  }

  void add(EditorLayer layer) {
    change(() {
      document.layers.add(layer);
      selected = document.layers.length - 1;
    });
  }

  void undo() {
    if (!canUndo) return;
    _future.add(document.copy());
    document = _past.removeLast();
    selected = -1;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _past.add(document.copy());
    document = _future.removeLast();
    selected = -1;
    notifyListeners();
  }

  void remove() {
    if (layer == null) return;
    change(() {
      document.layers.removeAt(selected);
      selected = -1;
    });
  }

  void select(int index) {
    selected = index;
    notifyListeners();
  }
}
