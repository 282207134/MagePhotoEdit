import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<String> savePng(Uint8List bytes, String name) async {
  if (Platform.isAndroid) {
    return await const MethodChannel('mage/export')
            .invokeMethod<String>('savePng', {'bytes': bytes, 'name': name}) ??
        'Pictures/Mage/$name';
  }
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes);
  return file.path;
}
